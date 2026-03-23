---
description: Perform a cleanup pass on the codebase
---
Perform a cleanup pass on the codebase. Do not change any logic or behavior — this is a refactoring-only pass.

$@

If a scope or extra instruction was provided above, restrict your work accordingly. Otherwise apply the cleanup to the entire codebase.

## Tasks

1. **Naming conventions** — Audit all identifiers (variables, functions, classes, modules, constants, files) and ensure they consistently follow the conventions of the language and the project's established style. Fix any violations. If conventions are ambiguous or mixed, pick the dominant pattern and apply it uniformly, noting your choice.

2. **Dead code** — Remove unused variables, parameters, and imports; unreachable code blocks; functions, methods, or classes never called or instantiated; and commented-out code that serves no documentation purpose.

3. **Duplicated code** — Identify repeated logic that is copy-pasted across the codebase and extract it into a shared function or module.

4. **Magic values** — Replace unexplained literals (numbers, strings) with named constants.

5. **Comments & documentation** — Remove or correct outdated comments that no longer match the code. Remove obvious comments that just restate what the code clearly does. Add missing docstrings to public functions, classes, and modules.

6. **Hardcoded configuration** — Flag or extract hardcoded credentials, URLs, file paths, or environment-specific values that should live in config or environment variables.

7. **Dependencies** — Remove unused dependencies; flag duplicated dependencies where two libraries serve the same purpose.

## Rules

- Do not alter logic, algorithms, or behavior.
- Do not add features or refactor structure beyond what is listed above.
- If a piece of dead code looks intentional (e.g., a public API surface, an exported symbol, a placeholder with a clear TODO), flag it with a comment rather than deleting it.
- After the pass, produce a short summary of what was changed and why, grouped by category.
