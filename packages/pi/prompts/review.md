---
description: Review code for bugs, logic errors, and quality issues
---
Perform a code review of the specified code. Do not modify any files — review only.

$@

If a scope was provided above, restrict your review accordingly. Otherwise review
the entire codebase.

## Scope

Review for:

- **Bugs** — logic errors, off-by-one mistakes, incorrect conditions, edge cases
- **Correctness** — does the code do what it claims?
- **Error handling** — missing null checks, unhandled exceptions, swallowed errors
- **Performance** — inefficient algorithms, unnecessary allocations, N+1 queries
- **Readability** — confusing variable names, convoluted logic, unclear intent
- **Maintainability** — tight coupling, god objects, missing abstractions
- **Test coverage** — are the critical paths tested? Are edge cases covered?

## Exclusions

- **Security** — do not comment on security issues. Use `security-review` instead.
- **Style preferences** — only flag violations of the project's established style.
- **Build issues** — lint and type errors are handled separately.

## Review Process

1. Identify the relevant files or modules to review.
2. Check for project style guides — look for `.editorconfig`, linter configs
   (e.g., `.eslintrc`, `prettier.config.js`), or style documentation.
   If no project style exists, infer from dominant patterns in the codebase.
3. Read the code thoroughly. Trace data flows and control paths.
3. For each finding, note:
   - File and line number
   - Category (bug, performance, readability, etc.)
   - Severity (high, medium, low)
   - Description of the issue
   - Specific recommendation

## Output Format

Provide a structured review:

### Overview
Brief summary of what was reviewed and overall code health.

### High Severity
Critical issues that should block merging.

### Medium Severity
Important issues that should be addressed before merging.

### Low Severity
Nice-to-have improvements or minor issues.

### Summary
Total findings grouped by category.

## Rules

- Be specific. Point to exact lines, not vague generalizations.
- Distinguish between facts and opinions. Flag style opinions as suggestions.
- Do not modify any files.
- If the code looks correct, say so.
