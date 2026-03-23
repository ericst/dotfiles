# Workflow Extension

A full-fledged workflow system with four explicit modes for structured task execution.

## Modes

The extension provides four mutually exclusive modes:

| Mode     | Description                                              |
|----------|----------------------------------------------------------|
| **think**  | Read-only tools, free-form dialogue, no plan expected |
| **plan**   | Read-only tools, agent produces a numbered plan        |
| **execute** | All tools + `step` tool, agent runs the plan autonomously |
| **full**   | All tools, no restrictions                             |

### Default Mode

New sessions start in **plan** mode by default.

### Startup Flags

Override the default mode with these flags:

- `--think-mode` — start in think mode
- `--plan-mode` — start in plan mode (same as default)
- `--full-mode` — start in full mode

There is intentionally **no `--execute-mode` flag**. Execute mode only makes sense when a plan already exists.

### Removing Old Flags

The old `--no-plan` flag has been removed.

## Commands & Shortcuts

| Command  | Shortcut    | Behavior                                                    |
|----------|-------------|-------------------------------------------------------------|
| `/think` | Ctrl+Alt+J  | Enter think mode                                            |
| `/plan`  | Ctrl+Alt+K  | Enter plan mode (aborts execution if currently in execute) |
| `/execute` | Ctrl+Alt+L | Enter execute mode (rejected if no todos extracted)       |
| `/full`  | Ctrl+Alt+H  | Enter full mode                                             |

No toggle behavior. Each command sets the mode unconditionally.

## Tool Sets

| Mode     | Available Tools                                                              |
|----------|-------------------------------------------------------------------------------|
| think    | read, bash, grep, find, ls, questionnaire, websearch, webfetch               |
| plan     | read, bash, grep, find, ls, questionnaire, websearch, webfetch               |
| execute  | read, bash, edit, write, step, websearch, webfetch                           |
| full     | read, bash, edit, write, websearch, webfetch                                 |

## The `step` Tool

The `step` tool replaces `plan_todo` for tracking progress during execution.

**Parameters:**
- `id` (number) — The step number to update
- `status` (string) — One of: `in_progress`, `completed`, `blocked`

**Status semantics:**
- `in_progress` — agent has started this step
- `completed` — agent has finished this step
- `blocked` — agent cannot continue without human input (must be preceded by a questionnaire call)

**Single in_progress enforcement:** Silent and self-healing. When a step is marked `in_progress`, any other step currently `in_progress` is silently reset to `pending`. No errors returned.

## Execution Flow

### Starting Execution (`/execute`)

1. Reject and notify if no todos have been extracted in the current plan
2. Freeze the todo list — no re-extraction from assistant messages during execution
3. Relaunch budget = number of incomplete steps + 2

### After Each Agent Stop (execute mode)

Evaluate in this order:

1. **All steps completed** → exit execute mode, enter plan mode, notify user
2. **Last tool call was questionnaire** → wait for user input, do not relaunch
3. **Relaunch budget > 0** → recalculate budget from remaining incomplete steps, auto-relaunch
4. **Relaunch budget exhausted** → exit execute mode, enter plan mode, notify user

### Questionnaire Answer Resets Budget

When the user sends a message while in execute mode and the last tool call was a questionnaire, the relaunch budget is recalculated before relaunching.

### Dynamic Budget

The relaunch budget is always `remaining incomplete steps + 2` — never manually decremented. Recalculated:
- After each `step(completed)` call
- On questionnaire reset
- At every agent stop before evaluating whether to relaunch

## Bash Command Guard

Destructive bash commands are blocked in **think** and **plan** modes.

### Blocked Commands

- File modification: `rm`, `mv`, `cp`, `mkdir`, `touch`, `chmod`, `chown`, etc.
- Git writes: `git add`, `git commit`, `git push`, `git pull`, `git merge`, etc.
- Package managers: `npm install`, `yarn add`, `pip install`, `apt install`, etc.
- System: `sudo`, `kill`, `reboot`, `shutdown`, `systemctl start/stop/restart`
- Editors: `vim`, `nano`, `emacs`, `code`

### Allowed Commands

- File inspection: `cat`, `head`, `tail`, `less`, `more`
- Search: `grep`, `find`, `rg`, `fd`
- Directory: `ls`, `pwd`, `tree`
- Git read-only: `git status`, `git log`, `git diff`, `git branch`
- Package info: `npm list`, `npm view`, `yarn info`
- System info: `uname`, `whoami`, `date`, `uptime`
- Sandboxed text processing: `gawk --sandbox`

Use `gawk --sandbox` instead of `awk` — it disables file writes and `system()` at runtime.

## Context Injection

A hidden system message is injected before each agent turn (except in full mode):

### Think Mode
> You are in think mode — a free-form space to help the user clarify their ideas before committing to a plan.
>
> Ask questions, explore trade-offs, push back on flawed ideas. Use the questionnaire tool for structured input. Do NOT produce a numbered plan.

### Plan Mode
> You are in plan mode — read-only exploration for safe code analysis.
>
> Use only: read, bash, grep, find, ls, questionnaire, websearch, webfetch. Do NOT use edit or write. Bash is restricted to allowlisted read-only commands. Produce a numbered plan under a `Plan:` header.

### Execute Mode
> You are executing the plan. Full tool access is enabled.
>
> Use the `step` tool to track progress. If blocked, use questionnaire and mark step as `blocked`. Original plan and current step statuses are provided.

## Context Filtering

Hidden context messages are stripped from conversation history when their mode is not active. Filtering occurs on mode transitions.

## Status Bar

| Mode     | Status Bar Text                                      |
|----------|------------------------------------------------------|
| think    | `Think` (muted)                                      |
| plan     | `Plan` (warning)                                     |
| execute  | `Executing X/Y (Z relaunches)` (accent)             |
| full     | `Full` (success)                                    |

## Widget

During execute mode, a todo list widget shows per-step status:
- `☑` (success) — completed
- `▶` (accent) — in_progress
- `⚠` (warning) — blocked
- `☐` (dim) — pending

## Persistence

State is persisted under the `workflow` key:
- `mode` — current workflow mode
- `todoItems` — extracted plan steps with statuses
- `relaunchBudget` — remaining budget for auto-relaunch
- `originalPlanText` — the original plan text

On session resume, all state is restored including relaunch budget. `step` tool results are replayed to reconstruct step statuses.

## Usage Example

1. **Start a new session** (defaults to plan mode)
2. **Explore code** using read-only tools
3. **Create a plan** under a `Plan:` header:

```
Plan:
1. Read the configuration file
2. Update the database schema
3. Deploy the new version
```

4. **Execute the plan** with `/execute`
5. **Track progress** using the `step` tool
6. **Handle blockers** with the questionnaire tool
7. **Complete** when all steps are done

## Session Resume

When resuming a session that was in execute mode:
- Todo list and all step statuses are restored
- Relaunch budget is restored
- Original plan text is restored
- Execution resumes from where it left off
