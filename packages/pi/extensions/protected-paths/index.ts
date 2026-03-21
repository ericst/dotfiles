/**
 * Protected Paths Extension
 *
 * Guards against writes to sensitive paths and locations outside the project,
 * across three tool surfaces:
 *
 *  write / edit
 *    The path argument is always explicit, so these are fully blocked whenever
 *    they target a protected pattern or resolve outside cwd / /tmp.
 *
 *  bash (static analysis)
 *    `extractWritePaths()` parses the command string to find concrete file paths
 *    that are likely write targets (redirections, tee, sed -i, cp/mv dest,
 *    dd of=, truncate, install).  Each extracted path is run through the same
 *    two checks used for write/edit.
 *
 *  bash (heuristic / suspicious patterns)
 *    When a write cannot be detected statically (shell variables in redirect
 *    targets, scripting one-liners, git restore, patch, rsync, etc.),
 *    `isBashSuspicious()` identifies the risk class and:
 *      • Interactive mode  → prompts the user to allow or block.
 *      • Non-interactive   → blocks automatically (safe default).
 *
 * Protection rules (shared by all three surfaces via checkPath()):
 *   1. Protected path patterns : .env, .git/, node_modules/
 *   2. Must resolve inside cwd or /tmp
 *
 * Known limits – things that cannot be caught by static analysis:
 *   • Paths fully hidden in variables  : echo hi > $SECRET
 *   • Writes through opaque binaries   : mytool --out=secret.txt
 *   • Compiled code run via bash       : ./malicious-binary
 *   • Multi-hop pipes to unknown tools : cmd | unknowntool
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { resolve } from "node:path";

/**
 * Analyzes a bash command string and returns all concrete file paths that the
 * command is likely to *write to*.  Paths containing shell variables or
 * command-substitution expressions (e.g. "$FILE", "$(pwd)/out") are silently
 * skipped here – the caller handles those via `isBashSuspicious()` instead.
 *
 * Patterns detected:
 *  • Output redirections  : >, >>, >|, &>, 2>, 1>
 *  • tee                  : tee [-a] [-i] <file>
 *  • sed -i               : sed -i[SUFFIX] … <file>  (last bare argument)
 *  • cp / mv              : the *destination* (last positional argument)
 *  • dd of=               : dd … of=<file>
 *  • truncate             : truncate -s <size> <file>
 *  • install              : install [opts] <src> <dest>  (last positional arg)
 *
 * What is NOT detected (fundamental limits of static analysis):
 *  • Paths held in shell variables : echo hi > $DEST
 *  • Paths built by command substitution : cat > "$(pwd)/out.txt"
 *  • Writes through arbitrary binaries  : mytool --output=secret.txt
 *  • Python/Perl/Node -c one-liners     : handled by isBashSuspicious()
 *  • Multi-hop pipes through unknowns   : cmd | unknowntool | tee ...
 */
function extractWritePaths(command: string): string[] {
	const paths: string[] = [];

	// Helper: reject tokens that are shell variables or substitutions –
	// they cannot be statically resolved.
	function isDynamic(token: string): boolean {
		return token.includes("$") || token.includes("`");
	}

	// Helper: add a token only when it looks like a plain file path.
	function add(token: string): void {
		if (!token || isDynamic(token)) return;
		// Strip surrounding quotes that may remain after a simple regex capture.
		const stripped = token.replace(/^['"]|['"]$/g, "");
		if (stripped && !isDynamic(stripped)) paths.push(stripped);
	}

	// ── 1. Output redirections ────────────────────────────────────────────────
	// Matches:  >, >>, >|, &>, 2>, 1>  followed by the destination token.
	// We deliberately skip  <  (input) and  2>&1  (fd-to-fd).
	// Negative look-behind on & ensures we don't re-match &> as plain >.
	// The destination token class already excludes < and > so that a trailing
	// heredoc ( <<< "val" ) is never absorbed into the captured path.
	const redirectRe = /(?:&>|[12]>|>>|>(?![>|]))\s*([^\s;|&<>'"]+)/g;
	for (const m of command.matchAll(redirectRe)) {
		// Skip fd-to-fd redirects like  2>&1  or  >&2
		if (/^&?\d+$/.test(m[1])) continue;
		add(m[1]);
	}

	// ── 2. tee ────────────────────────────────────────────────────────────────
	// Handles:  tee file  |  tee -a file  |  tee --append file  (last bare arg)
	const teeRe = /\btee\b((?:\s+(?:-\w+|--\w[\w-]*))*)\s+([^\s;|&'"]+)/g;
	for (const m of command.matchAll(teeRe)) {
		add(m[2]);
	}

	// ── 3. sed -i ────────────────────────────────────────────────────────────
	// Handles:  sed -i 's/a/b/' file  and  sed -i.bak 's/a/b/' file
	// The file is the last bare token after the script argument.
	const sedRe = /\bsed\b[^;|&\n]*?-i(?:\S*)\s+(?:'[^']*'|"[^"]*"|\S+)\s+([^\s;|&'"]+)/g;
	for (const m of command.matchAll(sedRe)) {
		add(m[1]);
	}

	// ── 4. cp / mv ───────────────────────────────────────────────────────────
	// cp [opts] src dest   or   mv [opts] src dest
	// We only care about the *destination* (last positional).
	// This simple heuristic captures the last whitespace-separated bare token
	// on the cp/mv line (stops at ;, |, &, newline, <, >).
	// NOTE: < and > are explicitly excluded so that heredoc operators (<<<, <<)
	// and redirections are never captured as path tokens — otherwise the real
	// destination would be shadowed by e.g. "<<<" becoming the last token.
	const cpMvRe = /\b(?:cp|mv)\b((?:\s+(?:-\w+|--\w[\w-]*))*(?:\s+[^\s;|&'"<>]+){2,})/g;
	for (const m of command.matchAll(cpMvRe)) {
		const tokens = m[1].trim().split(/\s+/).filter((t) => !t.startsWith("-"));
		if (tokens.length >= 2) add(tokens[tokens.length - 1]);
	}

	// ── 5. dd of= ─────────────────────────────────────────────────────────────
	const ddRe = /\bdd\b[^;|&\n]*\bof=([^\s;|&'"]+)/g;
	for (const m of command.matchAll(ddRe)) {
		add(m[1]);
	}

	// ── 6. truncate ───────────────────────────────────────────────────────────
	// truncate -s <size> <file>   or   truncate --size=<size> <file>
	const truncateRe = /\btruncate\b(?:\s+(?:-s\s+\S+|--size=\S+|\S+))*\s+([^\s;|&'"]+)/g;
	for (const m of command.matchAll(truncateRe)) {
		// Skip flags that start with - slipping through
		if (!m[1].startsWith("-")) add(m[1]);
	}

	// ── 7. install ────────────────────────────────────────────────────────────
	// install [opts] <src> <dest>  – same last-positional heuristic as cp/mv.
	// Same < > exclusion as cp/mv to prevent heredoc tokens shadowing the dest.
	const installRe = /\binstall\b((?:\s+(?:-\w+|--\w[\w-]*))*(?:\s+[^\s;|&'"<>]+){2,})/g;
	for (const m of command.matchAll(installRe)) {
		const tokens = m[1].trim().split(/\s+/).filter((t) => !t.startsWith("-"));
		if (tokens.length >= 2) add(tokens[tokens.length - 1]);
	}

	// Deduplicate while preserving order.
	return [...new Set(paths)];
}

export default function (pi: ExtensionAPI) {
	const protectedPaths = [".env", ".git/", "node_modules/"];

	function isAllowedRoot(absolutePath: string, cwd: string): boolean {
		const allowedRoots = [cwd, "/tmp"];
		return allowedRoots.some(
			(root) => absolutePath === root || absolutePath.startsWith(root.endsWith("/") ? root : root + "/")
		);
	}

	/**
	 * Detects bash commands that are likely to perform file writes but whose
	 * target paths cannot be statically extracted (variables, substitutions,
	 * opaque tools, etc.).  Returns a human-readable reason string when
	 * suspicious, or null when nothing concerning is found.
	 *
	 * Patterns detected:
	 *  • Scripting one-liners  : python/perl/ruby/node/bash -c "…"
	 *  • Variable-path redirects : echo hi > $DEST
	 *  • git write operations  : checkout, restore, apply, am, merge, rebase
	 *  • patch                 : always modifies files on disk
	 *  • Heredoc into redirect : cat <<EOF > file  (dynamic body, static target
	 *                            caught by extractWritePaths; this catches the rest)
	 *  • rsync                 : destination may be outside cwd
	 *  • chmod / chown         : not content writes but still modify protected dirs
	 */
	function isBashSuspicious(command: string): string | null {
		// Scripting one-liners with -c (or -e for perl/ruby) can open() and
		// write() any path.  perl and ruby use -e for inline code; awk programs
		// can redirect output to arbitrary files from within the script itself.
		if (/\b(?:python3?|perl|ruby|node|bash|sh|zsh)\b[^;|&\n]*\s-[ce][\s'"]/.test(command)) {
			return "scripting one-liner (-c/-e flag) may write to arbitrary paths";
		}
		if (/\bawk\b/.test(command)) {
			return "awk may redirect output to arbitrary paths from within its program";
		}

		// cp/mv/install with a special device or virtual file as the *source*
		// is a classic trick to pipe arbitrary data to a destination that looks
		// like a normal file argument (e.g. cp /dev/stdin /outside/path <<< data).
		// The destination IS extracted by extractWritePaths, but this guard adds
		// defence-in-depth and also catches cases where the destination is dynamic.
		if (/\b(?:cp|mv|install)\b[^;|&\n]*(?:\/dev\/(?:stdin|fd\/|zero|null|tcp\/|udp\/)|\/proc\/self\/fd\/)/.test(command)) {
			return "cp/mv/install with a special device source may write to arbitrary paths";
		}

		// Output redirection whose destination is a shell variable or substitution.
		if (/(?:&>|[12]?>|>>)\s*(?:\$|\()/.test(command)) {
			return "output redirection to a dynamically-computed path";
		}

		// git commands that restore/create/merge files on disk.
		if (/\bgit\b[^;|&\n]*\b(?:checkout|restore|apply|am|rebase|merge|cherry-pick|stash\s+pop)\b/.test(command)) {
			return "git command that may overwrite tracked files";
		}

		// patch always applies a diff to files on disk.
		if (/\bpatch\b/.test(command)) {
			return "patch command modifies files on disk";
		}

		// rsync destination could be anywhere.
		if (/\brsync\b/.test(command)) {
			return "rsync may write to paths outside the working directory";
		}

		// chmod / chown on a protected path pattern.
		if (/\b(?:chmod|chown)\b[^;|&\n]*(?:\.env|\.git\/|node_modules\/)/.test(command)) {
			return "chmod/chown targeting a protected path";
		}

		return null;
	}

	/**
	 * Resolves `rawPath` relative to `cwd` and runs both protection checks.
	 * Returns a block descriptor when the path is forbidden, null otherwise.
	 * This is the single source of truth for both the write/edit branch and
	 * the bash branch so the rules are always identical.
	 */
	function checkPath(
		rawPath: string,
		cwd: string,
	): { notifyMessage: string; blockReason: string } | null {
		// Check 1 — protected path patterns (operate on the raw string so that
		// both relative and absolute forms are caught before resolving).
		const matchedPattern = protectedPaths.find((p) => rawPath.includes(p));
		if (matchedPattern) {
			return {
				notifyMessage: `Blocked write to protected path: ${rawPath}`,
				blockReason: `Path "${rawPath}" matches protected pattern "${matchedPattern}"`,
			};
		}

		// Check 2 — must resolve to inside cwd or /tmp.
		const absolutePath = resolve(cwd, rawPath);
		if (!isAllowedRoot(absolutePath, cwd)) {
			return {
				notifyMessage: `Blocked write outside CWD and /tmp: ${absolutePath}`,
				blockReason: `Path "${absolutePath}" is outside the working directory and /tmp`,
			};
		}

		return null;
	}

	pi.on("tool_call", async (event, ctx) => {
		// ── write / edit ────────────────────────────────────────────────────────
		// Path is always explicit in the tool arguments — full static check.
		if (event.toolName === "write" || event.toolName === "edit") {
			const violation = checkPath(event.input.path as string, ctx.cwd);
			if (violation) {
				if (ctx.hasUI) ctx.ui.notify(violation.notifyMessage, "warning");
				return { block: true, reason: violation.blockReason };
			}
			return undefined;
		}

		// ── bash ────────────────────────────────────────────────────────────────
		if (event.toolName === "bash") {
			const command = event.input.command as string;

			// Step 2: For every concrete path the analyzer can extract, run the
			// same two-check rule used above.  First violation wins.
			for (const rawPath of extractWritePaths(command)) {
				const violation = checkPath(rawPath, ctx.cwd);
				if (violation) {
					if (ctx.hasUI) ctx.ui.notify(violation.notifyMessage, "warning");
					return { block: true, reason: `bash: ${violation.blockReason}` };
				}
			}

			// Step 3: For patterns we cannot statically resolve, ask the user.
			// In non-interactive mode (print / RPC without UI) we block to be safe.
			const suspicion = isBashSuspicious(command);
			if (suspicion) {
				if (!ctx.hasUI) {
					return {
						block: true,
						reason: `bash command blocked in non-interactive mode (${suspicion})`,
					};
				}
				const allowed = await ctx.ui.confirm(
					"Potentially unsafe bash command",
					`Reason: ${suspicion}\n\nCommand:\n${command}\n\nAllow execution?`,
				);
				if (!allowed) {
					return { block: true, reason: `bash command blocked by user (${suspicion})` };
				}
			}

			return undefined;
		}

		return undefined;
	});
}
