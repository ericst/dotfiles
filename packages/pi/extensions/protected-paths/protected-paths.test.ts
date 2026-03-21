/**
 * Tests for the protected-paths extension helper functions.
 *
 * Run with:  npx tsx ~/.pi/agent/extensions/protected-paths/protected-paths.test.ts
 *
 * These tests exercise extractWritePaths() and isBashSuspicious() in isolation
 * to verify that known bypass patterns are detected correctly.
 */

import { resolve } from "node:path";

// ─── Inline copies of the helpers under test ────────────────────────────────
// We duplicate them here so the test file is self-contained and doesn't need
// a module-export change in the extension.

function extractWritePaths(command: string): string[] {
	const paths: string[] = [];

	function isDynamic(token: string): boolean {
		return token.includes("$") || token.includes("`");
	}

	function add(token: string): void {
		if (!token || isDynamic(token)) return;
		const stripped = token.replace(/^['"]|['"]$/g, "");
		if (stripped && !isDynamic(stripped)) paths.push(stripped);
	}

	// 1. Output redirections — destination token must not contain < or >
	const redirectRe = /(?:&>|[12]>|>>|>(?![>|]))\s*([^\s;|&<>'"]+)/g;
	for (const m of command.matchAll(redirectRe)) {
		if (/^&?\d+$/.test(m[1])) continue;
		add(m[1]);
	}

	// 2. tee
	const teeRe = /\btee\b((?:\s+(?:-\w+|--\w[\w-]*))*)\s+([^\s;|&'"]+)/g;
	for (const m of command.matchAll(teeRe)) {
		add(m[2]);
	}

	// 3. sed -i
	const sedRe = /\bsed\b[^;|&\n]*?-i(?:\S*)\s+(?:'[^']*'|"[^"]*"|\S+)\s+([^\s;|&'"]+)/g;
	for (const m of command.matchAll(sedRe)) {
		add(m[1]);
	}

	// 4. cp / mv — token class excludes < and >
	const cpMvRe = /\b(?:cp|mv)\b((?:\s+(?:-\w+|--\w[\w-]*))*(?:\s+[^\s;|&'"<>]+){2,})/g;
	for (const m of command.matchAll(cpMvRe)) {
		const tokens = m[1].trim().split(/\s+/).filter((t) => !t.startsWith("-"));
		if (tokens.length >= 2) add(tokens[tokens.length - 1]);
	}

	// 5. dd of=
	const ddRe = /\bdd\b[^;|&\n]*\bof=([^\s;|&'"]+)/g;
	for (const m of command.matchAll(ddRe)) {
		add(m[1]);
	}

	// 6. truncate
	const truncateRe = /\btruncate\b(?:\s+(?:-s\s+\S+|--size=\S+|\S+))*\s+([^\s;|&'"]+)/g;
	for (const m of command.matchAll(truncateRe)) {
		if (!m[1].startsWith("-")) add(m[1]);
	}

	// 7. install — token class excludes < and >
	const installRe = /\binstall\b((?:\s+(?:-\w+|--\w[\w-]*))*(?:\s+[^\s;|&'"<>]+){2,})/g;
	for (const m of command.matchAll(installRe)) {
		const tokens = m[1].trim().split(/\s+/).filter((t) => !t.startsWith("-"));
		if (tokens.length >= 2) add(tokens[tokens.length - 1]);
	}

	return [...new Set(paths)];
}

function isBashSuspicious(command: string): string | null {
	if (/\b(?:python3?|perl|ruby|node|bash|sh|zsh)\b[^;|&\n]*\s-[ce][\s'"]/.test(command)) {
		return "scripting one-liner (-c/-e flag) may write to arbitrary paths";
	}
	if (/\bawk\b/.test(command)) {
		return "awk may redirect output to arbitrary paths from within its program";
	}
	if (/\b(?:cp|mv|install)\b[^;|&\n]*(?:\/dev\/(?:stdin|fd\/|zero|null|tcp\/|udp\/)|\/proc\/self\/fd\/)/.test(command)) {
		return "cp/mv/install with a special device source may write to arbitrary paths";
	}
	if (/(?:&>|[12]?>|>>)\s*(?:\$|\()/.test(command)) {
		return "output redirection to a dynamically-computed path";
	}
	if (/\bgit\b[^;|&\n]*\b(?:checkout|restore|apply|am|rebase|merge|cherry-pick|stash\s+pop)\b/.test(command)) {
		return "git command that may overwrite tracked files";
	}
	if (/\bpatch\b/.test(command)) {
		return "patch command modifies files on disk";
	}
	if (/\brsync\b/.test(command)) {
		return "rsync may write to paths outside the working directory";
	}
	if (/\b(?:chmod|chown)\b[^;|&\n]*(?:\.env|\.git\/|node_modules\/)/.test(command)) {
		return "chmod/chown targeting a protected path";
	}
	return null;
}

// ─── Minimal test harness ────────────────────────────────────────────────────

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

function expectContains(label: string, actual: string[], item: string) {
	const ok = actual.includes(item);
	if (ok) {
		console.log(`  ✅  ${label}`);
		passed++;
	} else {
		console.error(`  ❌  ${label}`);
		console.error(`       expected array to contain: ${item}`);
		console.error(`       got: ${JSON.stringify(actual)}`);
		failed++;
	}
}

function expectNotContains(label: string, actual: string[], item: string) {
	const ok = !actual.includes(item);
	if (ok) {
		console.log(`  ✅  ${label}`);
		passed++;
	} else {
		console.error(`  ❌  ${label}`);
		console.error(`       expected array NOT to contain: ${item}`);
		console.error(`       got: ${JSON.stringify(actual)}`);
		failed++;
	}
}

function expectSuspicious(label: string, command: string) {
	const result = isBashSuspicious(command);
	if (result !== null) {
		console.log(`  ✅  ${label} → "${result}"`);
		passed++;
	} else {
		console.error(`  ❌  ${label} — expected suspicious but got null`);
		failed++;
	}
}

function expectClean(label: string, command: string) {
	const result = isBashSuspicious(command);
	if (result === null) {
		console.log(`  ✅  ${label}`);
		passed++;
	} else {
		console.error(`  ❌  ${label} — expected clean but got: "${result}"`);
		failed++;
	}
}

// ─── Tests ───────────────────────────────────────────────────────────────────

console.log("\n── extractWritePaths ──────────────────────────────────────────");

console.log("\n  cp/mv with heredoc (the original bypass)");
expectContains(
	'cp /dev/stdin /outside/path <<< "yay"  →  extracts /outside/path',
	extractWritePaths('cp /dev/stdin /outside/path <<< "yay"'),
	"/outside/path",
);
expectNotContains(
	'cp /dev/stdin /outside/path <<< "yay"  →  does NOT extract <<<',
	extractWritePaths('cp /dev/stdin /outside/path <<< "yay"'),
	"<<<",
);

console.log("\n  cp/mv normal usage");
expectContains(
	"cp src.txt /tmp/dest.txt  →  extracts /tmp/dest.txt",
	extractWritePaths("cp src.txt /tmp/dest.txt"),
	"/tmp/dest.txt",
);
expectContains(
	"mv /tmp/a.txt /tmp/b.txt  →  extracts /tmp/b.txt",
	extractWritePaths("mv /tmp/a.txt /tmp/b.txt"),
	"/tmp/b.txt",
);

console.log("\n  install with heredoc");
expectContains(
	"install /dev/stdin /outside/bin <<< data  →  extracts /outside/bin",
	extractWritePaths("install /dev/stdin /outside/bin <<< data"),
	"/outside/bin",
);
expectNotContains(
	"install /dev/stdin /outside/bin <<< data  →  does NOT extract <<<",
	extractWritePaths("install /dev/stdin /outside/bin <<< data"),
	"<<<",
);

console.log("\n  redirections");
expectContains(
	"echo hi > /outside/file.txt  →  extracts /outside/file.txt",
	extractWritePaths("echo hi > /outside/file.txt"),
	"/outside/file.txt",
);
expectContains(
	"echo hi >> /tmp/log.txt  →  extracts /tmp/log.txt",
	extractWritePaths("echo hi >> /tmp/log.txt"),
	"/tmp/log.txt",
);
expectNotContains(
	"echo hi > file.txt <<< input  →  does NOT extract <<<",
	extractWritePaths("echo hi > file.txt <<< input"),
	"<<<",
);

console.log("\n  dd of=");
expectContains(
	"dd if=/dev/stdin of=/outside/img  →  extracts /outside/img",
	extractWritePaths("dd if=/dev/stdin of=/outside/img"),
	"/outside/img",
);

console.log("\n  tee");
expectContains(
	"cat file | tee /outside/copy  →  extracts /outside/copy",
	extractWritePaths("cat file | tee /outside/copy"),
	"/outside/copy",
);

console.log("\n── isBashSuspicious ───────────────────────────────────────────");

console.log("\n  /dev/stdin and device file sources");
expectSuspicious(
	'cp /dev/stdin /outside/path <<< "yay"',
	'cp /dev/stdin /outside/path <<< "yay"',
);
expectSuspicious(
	"cp /dev/fd/0 /outside/path",
	"cp /dev/fd/0 /outside/path",
);
expectSuspicious(
	"mv /proc/self/fd/0 /outside/path",
	"mv /proc/self/fd/0 /outside/path",
);

console.log("\n  scripting one-liners");
expectSuspicious("python3 -c one-liner",             "python3 -c 'open(\"/bad\",\"w\").write(\"x\")'");
expectSuspicious("python3 -c one-liner (no space)",  "python3 -c'open(\"/bad\",\"w\").write(\"x\")'");
expectSuspicious("python3 -c one-liner (dquote)",    'python3 -c"open(\\"/bad\\",\\"w\\").write(\\"x\\")"');
expectSuspicious("python -c one-liner (no space)",   "python -c'import os; os.unlink(\"x\")'");
expectSuspicious("perl -e one-liner",                "perl -e 'print \"yay\"' > /bad/path");
expectSuspicious("perl -e one-liner (no space)",     "perl -e'unlink q(/bad)'");
expectSuspicious("ruby -e one-liner",                "ruby -e 'File.write(\"/bad\",\"x\")'");
expectSuspicious("ruby -e one-liner (no space)",     "ruby -e'File.write(\"/bad\",\"x\")'");
expectSuspicious("node -e one-liner",                "node -e 'require(\"fs\").writeFileSync(\"/bad\",\"x\")'");
expectSuspicious("node -e one-liner (no space)",     "node -e'require(\"fs\").writeFileSync(\"/bad\",\"x\")'");
expectSuspicious("bash -c one-liner",                "bash -c 'echo hi > /bad'");
expectSuspicious("sh -c one-liner",                  "sh -c 'echo hi > /bad'");
expectSuspicious("sh -c one-liner (no space)",       "sh -c'echo hi > /bad'"  );

console.log("\n  awk");
expectSuspicious('awk redirect',         'awk \'{print > "/bad/path"}\' /dev/stdin');

console.log("\n  still-clean commands");
expectClean("ls -la",       "ls -la");
expectClean("cat file.txt", "cat file.txt");
expectClean("echo hello",   "echo hello");
expectClean("grep foo bar", "grep foo bar");

// ─── Summary ─────────────────────────────────────────────────────────────────

console.log(`\n${"─".repeat(60)}`);
console.log(`Results: ${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
