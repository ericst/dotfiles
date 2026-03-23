/**
 * Tests for the sandbox extension helper functions.
 *
 * Run with:
 *   npx tsx packages/pi/extensions/sandbox/sandbox.test.ts
 *
 * Self-contained: pure helpers are inlined so the test has no dependency on
 * the extension module itself (mirrors the approach of the old protected-paths
 * test file).
 */

import { homedir } from "node:os";
import { resolve, basename } from "node:path";

// ─── Inlined helpers under test ───────────────────────────────────────────────
// Keep these in sync with index.ts.
//
// TODO: index.ts already exports all of these identifiers (checkRead, checkWrite,
// normalizePath, matchesPathPattern, the mandatory-deny constants, mergeConfigs,
// DEFAULT_CONFIG, ExtensionSandboxConfig).  The test could import them directly
// to eliminate ~150 lines of duplication and the manual "keep in sync" burden.

// ── Mandatory read denies ─────────────────────────────────────────────────────

const MANDATORY_DENY_READ_PATHS: string[] = [
	`${homedir()}/.ssh`,
	`${homedir()}/.gnupg`,
	`${homedir()}/.aws`,
	`${homedir()}/.config/age`,
	`${homedir()}/.password-store`,
	`${homedir()}/.local/share/keyrings`,
	`${homedir()}/.kube`,
];

const MANDATORY_DENY_READ_FILES = new Set([
	".netrc",
	"id_rsa",
	"id_ecdsa",
	"id_ed25519",
	"id_ed25519_sk",
	"id_ecdsa_sk",
]);

// ── Mandatory write denies ────────────────────────────────────────────────────

const MANDATORY_DENY_FILES = new Set([
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

const MANDATORY_DENY_SUBPATHS = [
	"/.vscode/",
	"/.idea/",
	"/.claude/commands/",
	"/.claude/agents/",
	"/.git/hooks/",
	// Sandbox config files — prevent escaping the sandbox by rewriting its own config.
	"/.pi/sandbox.json",
	"/.pi/agent/extensions/sandbox.json",
];

interface FilesystemConfig {
	denyRead?: string[];
	allowRead?: string[];
	allowWrite?: string[];
	denyWrite?: string[];
}

interface TestSandboxConfig {
	filesystem?: FilesystemConfig;
}

function normalizePath(rawPath: string, cwd: string): string {
	const expanded = rawPath.startsWith("~") ? homedir() + rawPath.slice(1) : rawPath;
	return resolve(cwd, expanded);
}

function matchesPathPattern(absolutePath: string, pattern: string, cwd: string): boolean {
	if (pattern.includes("*") || pattern.includes("?")) {
		const base = basename(absolutePath);
		const regexStr = pattern
			.replace(/[.+^${}()|[\]\\]/g, "\\$&")
			.replace(/\*/g, ".*")
			.replace(/\?/g, ".");
		return new RegExp(`^${regexStr}$`).test(base);
	}
	const normalized = normalizePath(pattern, cwd);
	return absolutePath === normalized || absolutePath.startsWith(normalized + "/");
}

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
	if (absolutePath.endsWith("/.git/config") || absolutePath.includes("/.git/config/")) {
		return `writing to ".git/config" is always blocked (mandatory deny)`;
	}
	return null;
}

function checkRead(rawPath: string, config: TestSandboxConfig, cwd: string): string | null {
	const absolutePath = normalizePath(rawPath, cwd);

	// 1. Mandatory denies — always blocked, allowRead cannot override.
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

function checkWrite(rawPath: string, config: TestSandboxConfig, cwd: string): string | null {
	const absolutePath = normalizePath(rawPath, cwd);

	const mandatoryReason = matchesMandatoryDenyWrite(absolutePath);
	if (mandatoryReason) return mandatoryReason;

	const denyWrite = config.filesystem?.denyWrite;
	if (denyWrite?.some((p) => matchesPathPattern(absolutePath, p, cwd))) {
		return `write access to "${rawPath}" is denied by denyWrite rule`;
	}

	const allowWrite = config.filesystem?.allowWrite;
	const allowed = allowWrite?.some((p) => matchesPathPattern(absolutePath, p, cwd)) ?? false;
	if (!allowed) {
		return `"${rawPath}" is outside all allowed write locations`;
	}

	return null;
}

// ─── Config merge (inlined from index.ts) ────────────────────────────────────

interface ExtensionSandboxConfig {
	enabled?: boolean;
	networkEnabled?: boolean;
	network?: {
		allowedDomains?: string[];
		deniedDomains?: string[];
	};
	filesystem?: FilesystemConfig;
}

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

function mergeConfigs(
	base: ExtensionSandboxConfig,
	overrides: Partial<ExtensionSandboxConfig>,
): ExtensionSandboxConfig {
	const result = { ...base };
	if (overrides.enabled !== undefined) result.enabled = overrides.enabled;
	if (overrides.networkEnabled !== undefined) result.networkEnabled = overrides.networkEnabled;
	if (overrides.network) result.network = { ...base.network, ...overrides.network };
	if (overrides.filesystem) result.filesystem = { ...base.filesystem, ...overrides.filesystem };
	return result;
}

// ─── Test harness ─────────────────────────────────────────────────────────────

let passed = 0;
let failed = 0;

function expect(label: string, actual: unknown, expected: unknown) {
	const ok = JSON.stringify(actual) === JSON.stringify(expected);
	if (ok) {
		console.log(`  ✅  ${label}`);
		passed++;
	} else {
		console.error(`  ❌  ${label}`);
		console.error(`       expected: ${JSON.stringify(expected)}`);
		console.error(`       got:      ${JSON.stringify(actual)}`);
		failed++;
	}
}

function expectNull(label: string, actual: string | null) {
	if (actual === null) {
		console.log(`  ✅  ${label}`);
		passed++;
	} else {
		console.error(`  ❌  ${label} — expected null but got: "${actual}"`);
		failed++;
	}
}

function expectBlocked(label: string, actual: string | null) {
	if (actual !== null) {
		console.log(`  ✅  ${label} → "${actual}"`);
		passed++;
	} else {
		console.error(`  ❌  ${label} — expected a block reason but got null`);
		failed++;
	}
}

// ─── Tests ────────────────────────────────────────────────────────────────────

const CWD = "/home/user/project";
const HOME = homedir();

console.log("\n── normalizePath ──────────────────────────────────────────────");

expect(
	"~ expands to homedir",
	normalizePath("~/foo/bar", CWD),
	`${HOME}/foo/bar`,
);
expect(
	"relative path resolves against cwd",
	normalizePath("src/index.ts", CWD),
	`${CWD}/src/index.ts`,
);
expect(
	"absolute path is unchanged",
	normalizePath("/etc/hosts", CWD),
	"/etc/hosts",
);
expect(
	"dot resolves to cwd",
	normalizePath(".", CWD),
	CWD,
);

console.log("\n── matchesPathPattern ─────────────────────────────────────────");

console.log("\n  Directory prefix (no glob)");
expect(
	"~/.ssh matches a file inside ~/.ssh/",
	matchesPathPattern(`${HOME}/.ssh/id_rsa`, "~/.ssh", CWD),
	true,
);
expect(
	"~/.ssh matches the directory itself",
	matchesPathPattern(`${HOME}/.ssh`, "~/.ssh", CWD),
	true,
);
expect(
	"~/.ssh does not match an unrelated path",
	matchesPathPattern(`${HOME}/.config/foo`, "~/.ssh", CWD),
	false,
);
expect(
	"relative dir pattern matches nested file",
	matchesPathPattern(`${CWD}/src/foo.ts`, "src", CWD),
	true,
);
expect(
	"relative dir pattern does not match sibling dir",
	matchesPathPattern(`${CWD}/other/foo.ts`, "src", CWD),
	false,
);

console.log("\n  Glob patterns (basename matching)");
expect(
	"*.pem matches a .pem file",
	matchesPathPattern(`${CWD}/certs/server.pem`, "*.pem", CWD),
	true,
);
expect(
	"*.pem matches a .pem in a subdirectory",
	matchesPathPattern(`${CWD}/a/b/c/key.pem`, "*.pem", CWD),
	true,
);
expect(
	"*.pem does not match a .txt file",
	matchesPathPattern(`${CWD}/file.txt`, "*.pem", CWD),
	false,
);
expect(
	".env.* matches .env.local",
	matchesPathPattern(`${CWD}/.env.local`, ".env.*", CWD),
	true,
);
expect(
	".env.* matches .env.production",
	matchesPathPattern(`${CWD}/.env.production`, ".env.*", CWD),
	true,
);
expect(
	".env.* does not match plain .env",
	matchesPathPattern(`${CWD}/.env`, ".env.*", CWD),
	false,
);

console.log("\n── checkRead ──────────────────────────────────────────────────");

console.log("\n  Allowed cases");
expectNull(
	"regular source file is allowed",
	checkRead(`${CWD}/src/index.ts`, { filesystem: {} }, CWD),
);
expectNull(
	"file in /tmp is allowed",
	checkRead("/tmp/work.txt", { filesystem: {} }, CWD),
);
expectNull(
	"allowRead rescues a path inside a config denyRead region",
	checkRead(
		`${HOME}/project/src/main.ts`,
		{
			filesystem: {
				denyRead: [`${HOME}/project`],
				allowRead: [`${HOME}/project/src`],
			},
		},
		CWD,
	),
);
expectNull(
	"allowRead exact match rescues a config-denyRead path",
	checkRead(
		`${HOME}/project/secrets.txt`,
		{
			filesystem: {
				denyRead: [`${HOME}/project`],
				allowRead: [`${HOME}/project/secrets.txt`],
			},
		},
		CWD,
	),
);

console.log("\n  Blocked — config denyRead");
expectBlocked(
	"path matching a config denyRead directory is blocked",
	checkRead(
		`${HOME}/project/secrets.txt`,
		{
			filesystem: {
				denyRead: [`${HOME}/project`],
				allowRead: [`${HOME}/project/src`],
			},
		},
		CWD,
	),
);

console.log("\n  Blocked — mandatory read deny paths (hardcoded, allowRead cannot override)");
for (const dir of MANDATORY_DENY_READ_PATHS) {
	const file = `${dir}/somefile`;
	expectBlocked(
		`${dir}/* is always blocked`,
		checkRead(file, { filesystem: {} }, CWD),
	);
	expectBlocked(
		`${dir} itself is always blocked`,
		checkRead(dir, { filesystem: {} }, CWD),
	);
	// allowRead must NOT rescue a mandatory deny
	expectBlocked(
		`allowRead cannot rescue ${dir}`,
		checkRead(file, { filesystem: { allowRead: [dir, file] } }, CWD),
	);
}

console.log("\n  Blocked — mandatory read deny files (hardcoded, any location)");
for (const name of MANDATORY_DENY_READ_FILES) {
	expectBlocked(
		`${name} anywhere is always blocked`,
		checkRead(`${CWD}/some/path/${name}`, { filesystem: {} }, CWD),
	);
	expectBlocked(
		`allowRead cannot rescue ${name}`,
		checkRead(
			`${CWD}/some/path/${name}`,
			{ filesystem: { allowRead: [`${CWD}/some/path/${name}`] } },
			CWD,
		),
	);
}

console.log("\n── checkWrite ─────────────────────────────────────────────────");

const defaultFs: FilesystemConfig = {
	allowWrite: [".", "/tmp"],
	denyWrite: [".env", ".env.*", "*.pem", "*.key"],
};

console.log("\n  Allowed cases");
expectNull(
	"file inside cwd is allowed",
	checkWrite(`${CWD}/src/index.ts`, { filesystem: defaultFs }, CWD),
);
expectNull(
	"file in /tmp is allowed",
	checkWrite("/tmp/output.txt", { filesystem: defaultFs }, CWD),
);
expectNull(
	"nested directory inside cwd is allowed",
	checkWrite(`${CWD}/packages/foo/bar.ts`, { filesystem: defaultFs }, CWD),
);

console.log("\n  Blocked — denyWrite");
expectBlocked(
	".env is blocked by denyWrite",
	checkWrite(`${CWD}/.env`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".env.local is blocked by denyWrite glob",
	checkWrite(`${CWD}/.env.local`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	"server.pem is blocked by denyWrite glob",
	checkWrite(`${CWD}/certs/server.pem`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	"secret.key is blocked by denyWrite glob",
	checkWrite(`${CWD}/secret.key`, { filesystem: defaultFs }, CWD),
);

console.log("\n  Blocked — outside allowWrite");
expectBlocked(
	"home directory file outside cwd and /tmp is blocked",
	checkWrite(`${HOME}/Documents/report.txt`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	"/etc/hosts is blocked",
	checkWrite("/etc/hosts", { filesystem: defaultFs }, CWD),
);
expectBlocked(
	"sibling directory is blocked",
	checkWrite("/home/user/other-project/file.ts", { filesystem: defaultFs }, CWD),
);

console.log("\n  Blocked — mandatory deny files");
for (const name of MANDATORY_DENY_FILES) {
	expectBlocked(
		`${name} is always blocked`,
		checkWrite(`${CWD}/${name}`, { filesystem: defaultFs }, CWD),
	);
}

console.log("\n  Blocked — mandatory deny subpaths");
expectBlocked(
	".git/hooks/pre-commit is always blocked",
	checkWrite(`${CWD}/.git/hooks/pre-commit`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".git/hooks/post-merge is always blocked",
	checkWrite(`${CWD}/.git/hooks/post-merge`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".git/config is always blocked",
	checkWrite(`${CWD}/.git/config`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".vscode/settings.json is always blocked",
	checkWrite(`${CWD}/.vscode/settings.json`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".idea/workspace.xml is always blocked",
	checkWrite(`${CWD}/.idea/workspace.xml`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".claude/commands/foo.md is always blocked",
	checkWrite(`${CWD}/.claude/commands/foo.md`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	".claude/agents/bar.md is always blocked",
	checkWrite(`${CWD}/.claude/agents/bar.md`, { filesystem: defaultFs }, CWD),
);

console.log("\n  Blocked — sandbox config files (sandbox escape prevention)");
expectBlocked(
	"project-local .pi/sandbox.json is always blocked",
	checkWrite(`${CWD}/.pi/sandbox.json`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	"nested project .pi/sandbox.json is always blocked",
	checkWrite(`${HOME}/other-project/.pi/sandbox.json`, { filesystem: defaultFs }, CWD),
);
expectBlocked(
	"global sandbox.json is always blocked",
	checkWrite(`${HOME}/.pi/agent/extensions/sandbox.json`, { filesystem: defaultFs }, CWD),
);

console.log("\n── Config merging ─────────────────────────────────────────────");

const base = DEFAULT_CONFIG;

expect(
	"DEFAULT_CONFIG has enabled: true",
	base.enabled,
	true,
);
expect(
	"DEFAULT_CONFIG has networkEnabled: true",
	base.networkEnabled,
	true,
);

const withNetworkOff = mergeConfigs(base, { networkEnabled: false });
expect(
	"networkEnabled: false overrides default",
	withNetworkOff.networkEnabled,
	false,
);
expect(
	"other defaults preserved when only networkEnabled is overridden",
	withNetworkOff.enabled,
	true,
);
expect(
	"filesystem defaults preserved when only networkEnabled is overridden",
	withNetworkOff.filesystem?.allowWrite,
	[".", "/tmp"],
);

const withCustomDomains = mergeConfigs(base, {
	network: { allowedDomains: ["localhost", "127.0.0.1"] },
});
expect(
	"project allowedDomains fully replaces default list",
	withCustomDomains.network?.allowedDomains,
	["localhost", "127.0.0.1"],
);
expect(
	"other network fields preserved when only allowedDomains is overridden",
	withCustomDomains.network?.deniedDomains,
	[],
);

const withCustomFs = mergeConfigs(base, {
	filesystem: { allowWrite: ["/workspace", "/tmp"] },
});
expect(
	"project allowWrite fully replaces default",
	withCustomFs.filesystem?.allowWrite,
	["/workspace", "/tmp"],
);
expect(
	"other filesystem fields preserved when only allowWrite is overridden",
	withCustomFs.filesystem?.denyRead,
	[],
);

const withDisabled = mergeConfigs(base, { enabled: false });
expect(
	"enabled: false propagates",
	withDisabled.enabled,
	false,
);

// Three-level merge: base → global → project (project wins)
const globalOverride = mergeConfigs(base, { networkEnabled: false });
const projectOverride = mergeConfigs(globalOverride, { networkEnabled: true });
expect(
	"project config wins over global in three-level merge",
	projectOverride.networkEnabled,
	true,
);

// ─── Sandbox status labels ────────────────────────────────────────────────────
// Inlined from status.ts — keep in sync.

type SandboxStatusMode = "full" | "filesystem" | "disabled";

const SANDBOX_STATUS_LABELS: Record<SandboxStatusMode, string> = {
	full: "Sandbox (fs + net)",
	filesystem: "Sandbox (fs)",
	disabled: "Sandbox (disabled)",
};

console.log("\n── Sandbox status labels ──────────────────────────────────────");

expect(
	'"full" mode label is "Sandbox (fs + net)"',
	SANDBOX_STATUS_LABELS["full"],
	"Sandbox (fs + net)",
);
expect(
	'"filesystem" mode label is "Sandbox (fs)"',
	SANDBOX_STATUS_LABELS["filesystem"],
	"Sandbox (fs)",
);
expect(
	'"disabled" mode label is "Sandbox (disabled)"',
	SANDBOX_STATUS_LABELS["disabled"],
	"Sandbox (disabled)",
);
expect(
	"active modes are distinct from disabled",
	SANDBOX_STATUS_LABELS["full"] !== SANDBOX_STATUS_LABELS["disabled"] &&
		SANDBOX_STATUS_LABELS["filesystem"] !== SANDBOX_STATUS_LABELS["disabled"],
	true,
);
expect(
	"full and filesystem modes are distinct from each other",
	SANDBOX_STATUS_LABELS["full"] !== SANDBOX_STATUS_LABELS["filesystem"],
	true,
);

// ─── Summary ──────────────────────────────────────────────────────────────────

console.log(`\n${"─".repeat(60)}`);
console.log(`Results: ${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
