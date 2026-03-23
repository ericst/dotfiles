---
description: Stages all uncommitted changes and perform a commit. Does not push.
---

Inspect the current state of the repository and produce a single, well-formed
git commit covering all changes that should be committed together.

## Steps

1. Run `git status` to see what is staged, unstaged, and untracked.
2. Run `git diff` and `git diff --cached` to read the actual changes.
3. If nothing is staged, stage everything with `git add -A` — unless you see
   files that clearly should not be committed (build artefacts, secrets,
   editor swap files). Exclude those explicitly.
4. Write a commit message following the Conventional Commits format:

   <type>(<scope>): <short imperative summary>

   <optional body — explain the why, not the what, if non-obvious>

   Types: feat, fix, refactor, docs, test, chore, style, perf
   Scope: the module, file, or subsystem affected — omit if the change is truly cross-cutting.
   Summary: imperative mood, lowercase, no trailing period, ≤72 characters.
   Body: wrap at 72 characters. Only include if the diff alone does not make the intent clear.

5. Run `git commit -m "<message>"` — or `git commit -m "<subject>" -m "<body>"`
   if a body is warranted.
6. Confirm the commit was created with `git log -1 --oneline`.

## Constraints

- Do not push. Commit only.
- Do not modify any files. Read and commit only.
- If the working tree is clean, report that and stop — do not create an empty commit.
- If you are uncertain whether a file should be included, leave it unstaged and note it in your output.
