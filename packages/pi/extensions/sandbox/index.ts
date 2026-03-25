/**
 * Sandbox Extension
 *
 * Provides OS-level sandboxing for bash commands via @anthropic-ai/sandbox-runtime
 * (bubblewrap on Linux, sandbox-exec on macOS), plus a JS-level tool_call guard
 * for the read, write, and edit built-in tools.
 *
 * Configuration is loaded and merged in order:
 *   DEFAULT_CONFIG
 *     → ~/.pi/agent/extensions/sandbox.json  (global)
 *       → <cwd>/.pi/sandbox.json             (project-local, takes precedence)
 *
 * Key sandbox.json fields:
 *   enabled          – false to disable everything (default: true)
 *   networkEnabled   – false to keep filesystem sandbox but remove network isolation,
 *                      useful for projects needing raw TCP (e.g. Modbus) (default: true)
 *   network          – allowedDomains, deniedDomains, allowUnixSockets, etc.
 *   filesystem       – denyRead, allowRead, allowWrite, denyWrite, allowGitConfig
 *
 * Tool coverage:
 *   bash             – OS-level sandbox wraps every command
 *   user_bash (!/!!) – same sandbox applied to interactive shell commands
 *   read             – JS guard enforces denyRead / allowRead
 *   write / edit     – JS guard enforces allowWrite / denyWrite + mandatory denies
 *   websearch / webfetch – naturally exempt (use execFileSync in Node, never reach
 *                          the path-based tool_call handler)
 *
 * Mandatory write denies (always blocked, regardless of config):
 *   These mirror the library's built-in mandatory deny paths so that the write/edit
 *   tools receive the same protection that bash gets from the OS sandbox.
 *
 * networkEnabled: false implementation note:
 *   SandboxRuntimeConfig requires network.allowedDomains (Zod-typed as non-optional),
 *   but SandboxManager never calls SandboxRuntimeConfigSchema.parse() at runtime — it
 *   trusts TypeScript.  When networkEnabled is false we pass allowedDomains: undefined
 *   (cast through `as any`), which causes the manager's internal hasNetworkConfig check
 *   to resolve to false, so wrapCommandWithSandboxLinux omits --unshare-net while still
 *   applying the full filesystem restrictions.  No proxy servers are started.
 */

import { SandboxManager, type SandboxRuntimeConfig } from "@anthropic-ai/sandbox-runtime";
import type { ExtensionAPI, BashOperations } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType, createBashTool, getAgentDir } from "@mariozechner/pi-coding-agent";
import { setSandboxStatus, type SandboxStatusMode } from "../status.js";
import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve, basename } from "node:path";

// ─── Configuration types ─────────────────────────────────────────────────────

export interface ExtensionSandboxConfig {
	/** Set false to disable the sandbox entirely for this project. Default: true */
	enabled?: boolean;
	/**
	 * Set false to run filesystem sandbox without network isolation.
	 * Use for projects that need unrestricted TCP (Modbus, raw sockets, etc.).
	 * Default: true
	 */
	networkEnabled?: boolean;
	network?: {
		allowedDomains?: string[];
		deniedDomains?: string[];
		allowUnixSockets?: string[];
		allowAllUnixSockets?: boolean;
		allowLocalBinding?: boolean;
	};
	filesystem?: {
		denyRead?: string[];
		allowRead?: string[];
		allowWrite?: string[];
		denyWrite?: string[];
		allowGitConfig?: boolean;
	};
	ignoreViolations?: Record<string, string[]>;
	enableWeakerNestedSandbox?: boolean;
	mandatoryDenySearchDepth?: number;
}

// ─── Defaults ────────────────────────────────────────────────────────────────

const DEFAULT_CONFIG: ExtensionSandboxConfig = {
	enabled: true,
	networkEnabled: true,
	network: {
		allowedDomains: [
			"npmjs.org",
			"*.npmjs.org",
			"registry.npmjs.org",
			"registry.yarnpkg.com",
			"pypi.org",
			"*.pypi.org",
			"github.com",
			"*.github.com",
			"api.github.com",
			"raw.githubusercontent.com",
			"localhost",
			"127.0.0.1",
		],
		deniedDomains: [],
	},
	filesystem: {
		denyRead: [],
		allowRead: [],
		allowWrite: [".", "/tmp"],
		denyWrite: [".env", ".env.*", "*.pem", "*.key"],
	},
};

// ─── Mandatory read denies ────────────────────────────────────────────────────
// Hardcoded sensitive paths that are ALWAYS blocked from reads.
// These cannot be unlocked by any sandbox.json allowRead entry.

/** Absolute directory prefixes always blocked from reads. Resolved at module load. */
export const MANDATORY_DENY_READ_PATHS: string[] = [
	`${homedir()}/.ssh`,
	`${homedir()}/.gnupg`,
	`${homedir()}/.aws`,
	`${homedir()}/.config/age`,
	`${homedir()}/.password-store`,
	`${homedir()}/.local/share/keyrings`,
	`${homedir()}/.kube`,
];

/** Bare filenames always blocked from reads, regardless of location. */
export const MANDATORY_DENY_READ_FILES = new Set([
	".netrc",
	"id_rsa",
	"id_ecdsa",
	"id_ed25519",
	"id_ed25519_sk",
	"id_ecdsa_sk",
]);

// ─── Mandatory write denies ───────────────────────────────────────────────────
// Mirror the library's auto-protected paths for the JS-level write/edit guard.
// The OS sandbox enforces these for bash; we replicate the protection here.

/** Filenames always blocked from writes, regardless of location. */
export const MANDATORY_DENY_FILES = new Set([
	".bashrc",
	".bash_profile",
	".zshrc",
	".zprofile",
	".profile",
	".gitconfig",
	".gitmodules",
	".ripgreprc",
	".mcp.json",
]);

/** Path substrings always blocked from writes. */
export const MANDATORY_DENY_SUBPATHS = [
	"/.vscode/",
	"/.idea/",
	"/.claude/commands/",
	"/.claude/agents/",
	"/.git/hooks/",
	// Sandbox config files — prevent escaping the sandbox by rewriting its own config.
	"/.pi/sandbox.json",
	"/.pi/agent/extensions/sandbox.json",
];

// ─── Config loading ───────────────────────────────────────────────────────────

function mergeConfigs(
	base: ExtensionSandboxConfig,
	overrides: Partial<ExtensionSandboxConfig>,
): ExtensionSandboxConfig {
	const result = { ...base };
	if (overrides.enabled !== undefined) result.enabled = overrides.enabled;
	if (overrides.networkEnabled !== undefined) result.networkEnabled = overrides.networkEnabled;
	if (overrides.enableWeakerNestedSandbox !== undefined)
		result.enableWeakerNestedSandbox = overrides.enableWeakerNestedSandbox;
	if (overrides.mandatoryDenySearchDepth !== undefined)
		result.mandatoryDenySearchDepth = overrides.mandatoryDenySearchDepth;
	if (overrides.ignoreViolations !== undefined) result.ignoreViolations = overrides.ignoreViolations;
	// Shallow-merge sub-objects so users can override individual arrays without
	// having to repeat the entire network or filesystem block.
	if (overrides.network) result.network = { ...base.network, ...overrides.network };
	if (overrides.filesystem) result.filesystem = { ...base.filesystem, ...overrides.filesystem };
	return result;
}

export function loadConfig(cwd: string): ExtensionSandboxConfig {
	const globalConfigPath = join(getAgentDir(), "extensions", "sandbox.json");
	const projectConfigPath = join(cwd, ".pi", "sandbox.json");

	let globalConfig: Partial<ExtensionSandboxConfig> = {};
	let projectConfig: Partial<ExtensionSandboxConfig> = {};

	if (existsSync(globalConfigPath)) {
		try {
			globalConfig = JSON.parse(readFileSync(globalConfigPath, "utf-8"));
		} catch (e) {
			console.error(`[sandbox] Could not parse ${globalConfigPath}: ${e}`);
		}
	}
	if (existsSync(projectConfigPath)) {
		try {
			projectConfig = JSON.parse(readFileSync(projectConfigPath, "utf-8"));
		} catch (e) {
			console.error(`[sandbox] Could not parse ${projectConfigPath}: ${e}`);
		}
	}

	return mergeConfigs(mergeConfigs(DEFAULT_CONFIG, globalConfig), projectConfig);
}

// ─── Path helpers ─────────────────────────────────────────────────────────────

/** Expand ~ and resolve relative paths against cwd to an absolute path. */
export function normalizePath(rawPath: string, cwd: string): string {
	const expanded = rawPath.startsWith("~") ? homedir() + rawPath.slice(1) : rawPath;
	return resolve(cwd, expanded);
}

/**
 * Returns true when absolutePath matches a config pattern.
 *
 * - Glob patterns (containing * or ?): matched against the basename only,
 *   with * → .* and ? → . (covers *.pem, .env.*, etc.).
 * - Plain patterns: matched as a path prefix, so both the path itself and
 *   everything nested inside it are covered.
 */
export function matchesPathPattern(absolutePath: string, pattern: string, cwd: string): boolean {
	if (pattern.includes("*") || pattern.includes("?")) {
		const base = basename(absolutePath);
		const regexStr = pattern
			.replace(/[.+^${}()|[\]\\]/g, "\\$&") // escape regex specials except * and ?
			.replace(/\*/g, ".*")
			.replace(/\?/g, ".");
		return new RegExp(`^${regexStr}$`).test(base);
	}
	const normalized = normalizePath(pattern, cwd);
	return absolutePath === normalized || absolutePath.startsWith(normalized + "/");
}

// ─── Access checks ────────────────────────────────────────────────────────────

/**
 * Check whether reading rawPath is permitted under the given config.
 * Returns a block-reason string, or null if access is allowed.
 *
 * Evaluation order:
 *   1. Mandatory deny paths/files (always blocked, allowRead cannot override).
 *   2. Config-based denyRead / allowRead (deny-then-allow):
 *      - If nothing in denyRead matches  → allowed.
 *      - If a denyRead entry matches but an allowRead entry also matches → allowed.
 *      - If a denyRead entry matches and no allowRead entry rescues it   → blocked.
 */
export function checkRead(
	rawPath: string,
	config: ExtensionSandboxConfig,
	cwd: string,
): string | null {
	const absolutePath = normalizePath(rawPath, cwd);

	// 1. Mandatory denies — always blocked, config cannot override.
	const mandatoryReason = matchesMandatoryDenyRead(absolutePath);
	if (mandatoryReason) return mandatoryReason;

	// 2. Config-based denyRead / allowRead.
	const denyRead = config.filesystem?.denyRead;
	if (!denyRead?.length) return null;

	const denied = denyRead.some((p) => matchesPathPattern(absolutePath, p, cwd));
	if (!denied) return null;

	const allowRead = config.filesystem?.allowRead;
	const rescued = allowRead?.some((p) => matchesPathPattern(absolutePath, p, cwd)) ?? false;
	if (rescued) return null;

	return `read access to "${rawPath}" is denied by denyRead rule`;
}

/**
 * Check whether writing to rawPath is permitted under the given config.
 * Returns a block-reason string, or null if access is allowed.
 *
 * Evaluation order:
 *   1. Mandatory deny files/subpaths (always blocked, config cannot override).
 *   2. User-configured denyWrite (takes precedence over allowWrite).
 *   3. User-configured allowWrite (path must match at least one entry).
 */
export function checkWrite(
	rawPath: string,
	config: ExtensionSandboxConfig,
	cwd: string,
): string | null {
	const absolutePath = normalizePath(rawPath, cwd);

	// 1. Mandatory denies — mirror the library's always-blocked paths.
	const mandatoryReason = matchesMandatoryDenyWrite(absolutePath);
	if (mandatoryReason) return mandatoryReason;

	// 2. User-configured denyWrite.
	const denyWrite = config.filesystem?.denyWrite;
	if (denyWrite?.some((p) => matchesPathPattern(absolutePath, p, cwd))) {
		return `write access to "${rawPath}" is denied by denyWrite rule`;
	}

	// 3. Must be within at least one allowWrite entry.
	const allowWrite = config.filesystem?.allowWrite;
	const allowed = allowWrite?.some((p) => matchesPathPattern(absolutePath, p, cwd)) ?? false;
	if (!allowed) {
		return `"${rawPath}" is outside all allowed write locations`;
	}

	return null;
}

/** Returns a block reason if absolutePath matches a mandatory read deny, null otherwise. */
function matchesMandatoryDenyRead(absolutePath: string): string | null {
	const base = basename(absolutePath);
	if (MANDATORY_DENY_READ_FILES.has(base)) {
		return `reading "${base}" is always blocked (mandatory deny)`;
	}
	for (const dir of MANDATORY_DENY_READ_PATHS) {
		if (absolutePath === dir || absolutePath.startsWith(dir + "/")) {
			return `reading within "${dir}" is always blocked (mandatory deny)`;
		}
	}
	return null;
}

/** Returns a block reason if absolutePath matches a mandatory write deny, null otherwise. */
function matchesMandatoryDenyWrite(absolutePath: string): string | null {
	const base = basename(absolutePath);
	if (MANDATORY_DENY_FILES.has(base)) {
		return `writing to "${base}" is always blocked (mandatory deny)`;
	}
	for (const sub of MANDATORY_DENY_SUBPATHS) {
		if (absolutePath.includes(sub)) {
			return `writing within "${sub.replaceAll("/", "")}" is always blocked (mandatory deny)`;
		}
	}
	// .git/config specifically (end-of-path and as a directory component)
	if (absolutePath.endsWith("/.git/config") || absolutePath.includes("/.git/config/")) {
		return `writing to ".git/config" is always blocked (mandatory deny)`;
	}
	return null;
}

// ─── SandboxRuntimeConfig builder ────────────────────────────────────────────

/**
 * Builds the filesystem portion of a SandboxRuntimeConfig from the extension
 * config. Prepends the mandatory read-deny paths so bubblewrap enforces them
 * for bash commands, mirroring the JS-level read-tool guard.
 *
 * Extracted to avoid duplicating this object literal between buildRuntimeConfig
 * (full sandbox) and the filesystem-only path in createSandboxedBashOps.
 */
function buildFilesystemRuntimeConfig(
	config: ExtensionSandboxConfig,
): SandboxRuntimeConfig["filesystem"] {
	return {
		// Prepend hardcoded mandatory read denies so the OS-level sandbox (bubblewrap)
		// also enforces them for bash commands, not just the JS read-tool guard.
		denyRead: [...MANDATORY_DENY_READ_PATHS, ...(config.filesystem?.denyRead ?? [])],
		allowRead: config.filesystem?.allowRead,
		allowWrite: config.filesystem?.allowWrite ?? [],
		denyWrite: config.filesystem?.denyWrite ?? [],
		allowGitConfig: config.filesystem?.allowGitConfig,
	};
}

function buildRuntimeConfig(config: ExtensionSandboxConfig): SandboxRuntimeConfig {
	return {
		network: {
			allowedDomains: config.network?.allowedDomains ?? [],
			deniedDomains: config.network?.deniedDomains ?? [],
			allowUnixSockets: config.network?.allowUnixSockets,
			allowAllUnixSockets: config.network?.allowAllUnixSockets,
			allowLocalBinding: config.network?.allowLocalBinding,
		},
		filesystem: buildFilesystemRuntimeConfig(config),
		ignoreViolations: config.ignoreViolations,
		enableWeakerNestedSandbox: config.enableWeakerNestedSandbox,
		mandatoryDenySearchDepth: config.mandatoryDenySearchDepth,
	};
}

// ─── Sandboxed bash operations ────────────────────────────────────────────────

/** Multiplier used to convert the timeout value (seconds) to milliseconds. */
const TIMEOUT_MS_PER_SECOND = 1000;

/**
 * Returns a BashOperations implementation that wraps every command with the
 * OS-level sandbox before spawning it.
 *
 * When networkInitialized is true, SandboxManager.wrapWithSandbox() uses the
 * config stored by the earlier SandboxManager.initialize() call (full sandbox).
 *
 * When networkInitialized is false (networkEnabled: false mode), we call
 * wrapWithSandbox with an explicit customConfig that carries the filesystem
 * rules but passes allowedDomains: undefined.  At runtime, SandboxManager
 * never Zod-validates the incoming config, so the undefined propagates into
 * the internal hasNetworkConfig check, which resolves to false, causing
 * wrapCommandWithSandboxLinux to omit --unshare-net while still applying full
 * filesystem restrictions via bubblewrap.
 */
function createSandboxedBashOps(
	config: ExtensionSandboxConfig,
	networkInitialized: boolean,
): BashOperations {
	return {
		async exec(command, cwd, { onData, signal, timeout }) {
			if (!existsSync(cwd)) {
				throw new Error(`Working directory does not exist: ${cwd}`);
			}

			let wrappedCommand: string;
			if (networkInitialized) {
				wrappedCommand = await SandboxManager.wrapWithSandbox(command);
			} else {
				// filesystem-only: pass allowedDomains: undefined to skip --unshare-net.
				wrappedCommand = await SandboxManager.wrapWithSandbox(
					command,
					undefined,
					{
						filesystem: buildFilesystemRuntimeConfig(config),
						network: { allowedDomains: undefined, deniedDomains: [] },
					// eslint-disable-next-line @typescript-eslint/no-explicit-any
					} as any,
				);
			}

			return new Promise((resolve, reject) => {
				const child = spawn("bash", ["-c", wrappedCommand], {
					cwd,
					detached: true,
					stdio: ["ignore", "pipe", "pipe"],
				});

				let timedOut = false;
				let timeoutHandle: NodeJS.Timeout | undefined;

				if (timeout !== undefined && timeout > 0) {
					timeoutHandle = setTimeout(() => {
						timedOut = true;
						if (child.pid) {
							try {
								process.kill(-child.pid, "SIGKILL");
							} catch {
								child.kill("SIGKILL");
							}
						}
					}, timeout * TIMEOUT_MS_PER_SECOND);
				}

				child.stdout?.on("data", onData);
				child.stderr?.on("data", onData);

				child.on("error", (err) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					reject(err);
				});

				const onAbort = () => {
					if (child.pid) {
						try {
							process.kill(-child.pid, "SIGKILL");
						} catch {
							child.kill("SIGKILL");
						}
					}
				};
				signal?.addEventListener("abort", onAbort, { once: true });

				child.on("close", (code) => {
					if (timeoutHandle) clearTimeout(timeoutHandle);
					signal?.removeEventListener("abort", onAbort);
					SandboxManager.cleanupAfterCommand();

					if (signal?.aborted) {
						reject(new Error("aborted"));
					} else if (timedOut) {
						reject(new Error(`timeout:${timeout}`));
					} else {
						resolve({ exitCode: code });
					}
				});
			});
		},
	};
}

// ─── Extension entry point ────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	pi.registerFlag("no-sandbox", {
		description: "Disable all OS-level sandboxing for bash commands (filesystem + network isolation)",
		type: "boolean",
		default: false,
	});

	pi.registerFlag("no-net-sandbox", {
		description: "Disable network isolation while keeping filesystem sandbox active",
		type: "boolean",
		default: false,
	});

	const localCwd = process.cwd();
	const localBash = createBashTool(localCwd);

	let sandboxEnabled = false;
	let networkInitialized = false;
	let activeConfig: ExtensionSandboxConfig | null = null;

	// Replace the built-in bash tool with the sandboxed variant.
	// Falls back to unsandboxed execution when the sandbox is disabled.
	pi.registerTool({
		...localBash,
		label: "bash (sandboxed)",
		async execute(id, params, signal, onUpdate, _ctx) {
			if (!sandboxEnabled || !activeConfig) {
				return localBash.execute(id, params, signal, onUpdate);
			}
			const sandboxedBash = createBashTool(localCwd, {
				operations: createSandboxedBashOps(activeConfig, networkInitialized),
			});
			return sandboxedBash.execute(id, params, signal, onUpdate);
		},
	});

	// Apply the same sandbox to interactive ! / !! commands.
	pi.on("user_bash", () => {
		if (!sandboxEnabled || !activeConfig) return;
		return { operations: createSandboxedBashOps(activeConfig, networkInitialized) };
	});

	// JS-level guard for read, write, and edit tools.
	// websearch and webfetch use execFileSync internally and never reach this handler.
	pi.on("tool_call", async (event, ctx) => {
		if (!sandboxEnabled || !activeConfig) return undefined;

		if (isToolCallEventType("read", event)) {
			const reason = checkRead(event.input.path, activeConfig, ctx.cwd);
			if (reason) {
				if (ctx.hasUI) ctx.ui.notify(`Read blocked: ${event.input.path}`, "warning");
				return { block: true, reason };
			}
		}

		if (isToolCallEventType("write", event)) {
			const reason = checkWrite(event.input.path, activeConfig, ctx.cwd);
			if (reason) {
				if (ctx.hasUI) ctx.ui.notify(`Write blocked: ${event.input.path}`, "warning");
				return { block: true, reason };
			}
		}

		if (isToolCallEventType("edit", event)) {
			const reason = checkWrite(event.input.path, activeConfig, ctx.cwd);
			if (reason) {
				if (ctx.hasUI) ctx.ui.notify(`Edit blocked: ${event.input.path}`, "warning");
				return { block: true, reason };
			}
		}

		return undefined;
	});

	// Initialise the sandbox at session start.
	pi.on("session_start", async (_event, ctx) => {
		const noSandbox = pi.getFlag("no-sandbox") as boolean;

		if (noSandbox) {
			sandboxEnabled = false;
			setSandboxStatus("disabled", ctx);
			ctx.ui.notify("Sandbox disabled via --no-sandbox (filesystem + network)", "warning");
			return;
		}

		const config = loadConfig(ctx.cwd);

		const noNetSandbox = pi.getFlag("no-net-sandbox") as boolean;

		if (!config.enabled) {
			sandboxEnabled = false;
			setSandboxStatus("disabled", ctx);
			ctx.ui.notify("Sandbox disabled via config", "info");
			return;
		}

		const platform = process.platform;
		if (platform !== "darwin" && platform !== "linux") {
			sandboxEnabled = false;
			setSandboxStatus("disabled", ctx);
			ctx.ui.notify(`Sandbox not supported on ${platform}`, "warning");
			return;
		}

		const deps = SandboxManager.checkDependencies();
		if (deps.errors.length > 0) {
			sandboxEnabled = false;
			setSandboxStatus("disabled", ctx);
			ctx.ui.notify(`Sandbox unavailable: ${deps.errors.join(", ")}`, "error");
			return;
		}
		if (deps.warnings.length > 0) {
			ctx.ui.notify(`Sandbox warnings: ${deps.warnings.join(", ")}`, "warning");
		}

		if (noNetSandbox || config.networkEnabled === false) {
			// Skip network initialization - filesystem sandbox remains active.
			// When noNetSandbox is set, this is explicit (overrides config.networkEnabled).
			// When config.networkEnabled is false, it's configured via sandbox.json.
		} else {
			try {
				await SandboxManager.initialize(buildRuntimeConfig(config));
				networkInitialized = true;
			} catch (err) {
				sandboxEnabled = false;
				setSandboxStatus("disabled", ctx);
				ctx.ui.notify(
					`Sandbox init failed: ${err instanceof Error ? err.message : err}`,
					"error",
				);
				return;
			}
		}

		sandboxEnabled = true;
		activeConfig = config;

		const sandboxMode: SandboxStatusMode = networkInitialized ? "full" : "filesystem";
		setSandboxStatus(sandboxMode, ctx);
		const modeLabel = networkInitialized ? "filesystem + network" : "filesystem only";
		const flagNote = noNetSandbox ? " (via --no-net-sandbox)" : "";
		ctx.ui.notify(`Sandbox active (${modeLabel})${flagNote}`, "info");
	});

	pi.on("session_shutdown", async () => {
		if (networkInitialized) {
			try {
				await SandboxManager.reset();
			} catch {
				// ignore cleanup errors
			}
			networkInitialized = false;
		}
		sandboxEnabled = false;
		activeConfig = null;
	});

	pi.registerCommand("sandbox", {
		description: "Show current sandbox configuration",
		handler: async (_args, ctx) => {
			if (!sandboxEnabled || !activeConfig) {
				ctx.ui.notify("Sandbox is disabled", "info");
				return;
			}

			const config = activeConfig;
			const lines = [
				"Sandbox Configuration",
				"",
				`Status:  active`,
				`Network: ${networkInitialized ? "enabled (host-filtered)" : "disabled (filesystem only)"}`,
			];

			if (networkInitialized) {
				lines.push(
					`  Allowed domains:  ${config.network?.allowedDomains?.join(", ") || "(none)"}`,
					`  Denied domains:   ${config.network?.deniedDomains?.join(", ") || "(none)"}`,
				);
			}

			lines.push(
				"",
				"Filesystem:",
				`  denyRead:   ${config.filesystem?.denyRead?.join(", ") || "(none)"}`,
				`  allowRead:  ${config.filesystem?.allowRead?.join(", ") || "(none)"}`,
				`  allowWrite: ${config.filesystem?.allowWrite?.join(", ") || "(none)"}`,
				`  denyWrite:  ${config.filesystem?.denyWrite?.join(", ") || "(none)"}`,
				"",
				"Mandatory read denies (always active, allowRead cannot override):",
				`  Dirs:  ${MANDATORY_DENY_READ_PATHS.join(", ")}`,
				`  Files: ${[...MANDATORY_DENY_READ_FILES].join(", ")}`,
				"",
				"Mandatory write denies (always active):",
				`  Files:    ${[...MANDATORY_DENY_FILES].join(", ")}`,
				`  Subpaths: ${MANDATORY_DENY_SUBPATHS.map((s) => s.replaceAll("/", "")).join(", ")}, .git/config`,
			);

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
