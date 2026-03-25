/**
 * Workflow Extension
 *
 * A full-fledged workflow system with four explicit modes:
 * - think  — read-only tools, free-form dialogue
 * - plan   — read-only tools, agent produces a numbered plan
 * - execute — all tools + step tool, agent runs the plan autonomously
 * - full   — all tools, no restrictions
 *
 * Features:
 * - Four mutually exclusive modes with explicit commands and shortcuts
 * - Startup flags: --think-mode, --plan-mode, --full-mode
 * - step tool (replaces plan_todo) for tracking progress
 * - Dynamic relaunch budget (remaining incomplete steps + 2)
 * - Context injection before each agent turn
 * - Context filtering on mode transitions
 * - Session persistence
 * - Status bar integration
 */

import type { AgentMessage } from "@mariozechner/pi-agent-core";
import { StringEnum } from "@mariozechner/pi-ai";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key, Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { extractTodoItems, isSafeCommand, type TodoItem } from "./utils.js";
import { setStatus, type WorkflowMode } from "../status.js";

// Tool sets per mode (think and plan share the same read-only set)
const READ_ONLY_TOOLS = ["read", "bash", "grep", "find", "ls",  "websearch", "webfetch"];
const EXECUTE_TOOLS = ["read", "bash", "edit", "write", "step", "websearch", "webfetch"];
const FULL_TOOLS = ["read", "bash", "edit", "write", "websearch", "webfetch"];

/** Extra relaunch slots added on top of the remaining incomplete step count. */
const BUDGET_BUFFER = 2;

/** Key used when persisting workflow state to the session entry store. */
const PERSIST_KEY = "workflow";

/** Widget key used for the todo list panel during execute mode. */
const WIDGET_ID = "workflow-todos";

/** Render the todo list as a widget panel. Pass an empty array to clear. */
function setTodoWidget(todos: Array<{ step: number; text: string; status: string }>, ctx: ExtensionContext): void {
	if (!ctx.hasUI) return;

	if (todos.length === 0) {
		ctx.ui.setWidget(WIDGET_ID, undefined);
		return;
	}

	const theme = ctx.ui.theme;
	const lines = todos.map((item) => {
		if (item.status === "completed") {
			return theme.fg("success", "☑ ") + theme.fg("muted", theme.strikethrough(item.text));
		}
		if (item.status === "in_progress") {
			return theme.fg("accent", "▶ ") + theme.fg("text", item.text);
		}
		if (item.status === "blocked") {
			return theme.fg("error", "⚠ ") + theme.fg("warning", item.text);
		}
		return `${theme.fg("dim", "☐ ")}${theme.fg("muted", item.text)}`;
	});

	ctx.ui.setWidget(WIDGET_ID, lines);
}

/** Remove the todo list widget panel. */
function clearTodoWidget(ctx: ExtensionContext): void {
	if (ctx.hasUI) {
		ctx.ui.setWidget(WIDGET_ID, undefined);
	}
}

/** Returns true when `m` is a fully-formed assistant message with a content array. */
function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray((m as AssistantMessage).content);
}

/** Concatenates all text blocks from an assistant message into a single string. */
function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

export default function workflowExtension(pi: ExtensionAPI): void {
	// ── State ─────────────────────────────────────────────────────────────────
	let currentMode: WorkflowMode = "think";
	let todoItems: TodoItem[] = [];
	let relaunchBudget = 0;
	let originalPlanText = "";
	let frozenTodoList = false; // Freeze todo list during execution

	// ── Persistence ───────────────────────────────────────────────────────────

	/** Snapshot the current workflow state into the session entry store. */
	function persistState(): void {
		pi.appendEntry(PERSIST_KEY, {
			mode: currentMode,
			todoItems: todoItems,
			relaunchBudget: relaunchBudget,
			originalPlanText: originalPlanText,
		});
	}

	// ── UI Updates ─────────────────────────────────────────────────────────────

	/** Refresh the status bar and todo widget to reflect the current mode and step progress. */
	function updateStatus(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;

		if (currentMode === "execute" && todoItems.length > 0) {
			const completed = todoItems.filter((t) => t.status === "completed").length;
			setStatus(currentMode, {
				theme: ctx.ui.theme,
				completedSteps: completed,
				totalSteps: todoItems.length,
				relaunchBudget: relaunchBudget,
			}, ctx);
			setTodoWidget(todoItems, ctx);
		} else {
			setStatus(currentMode, { theme: ctx.ui.theme }, ctx);
			clearTodoWidget(ctx);
		}
	}

	/** Relaunch budget = incomplete steps + a fixed buffer so minor hiccups don't stall execution. */
	function calculateBudget(): number {
		const remaining = todoItems.filter((t) => t.status !== "completed").length;
		return remaining + BUDGET_BUFFER;
	}

	// ── Mode Switching ─────────────────────────────────────────────────────────

	/**
	 * Switch to a new workflow mode: update active tools, status bar, and persist.
	 * Always resets `frozenTodoList`; callers entering execute mode re-set it after.
	 */
	function setMode(mode: WorkflowMode, ctx: ExtensionContext): void {
		currentMode = mode;
		frozenTodoList = false;

		switch (mode) {
			case "think":
				pi.setActiveTools(READ_ONLY_TOOLS);
				break;
			case "plan":
				pi.setActiveTools(READ_ONLY_TOOLS);
				break;
			case "execute":
				pi.setActiveTools(EXECUTE_TOOLS);
				break;
			case "full":
				pi.setActiveTools(FULL_TOOLS);
				break;
		}

		updateStatus(ctx);
		persistState();
	}

	// ── Execution Helpers ──────────────────────────────────────────────────────

	/**
	 * Clear execution state when leaving execute mode early (think/plan/full commands).
	 * No-op when not currently in execute mode.
	 */
	function abortExecution(): void {
		if (currentMode !== "execute") return;
		todoItems = [];
		originalPlanText = "";
		relaunchBudget = 0;
	}

	/**
	 * Freeze the todo list, set the relaunch budget, enter execute mode, and
	 * send the kick-off message that triggers the first agent turn.
	 */
	function startExecution(ctx: ExtensionContext): void {
		frozenTodoList = true;
		relaunchBudget = calculateBudget();
		setMode("execute", ctx);
		// NOTE: setMode resets frozenTodoList to false, so we re-set it here.
		// The flag guards todo re-extraction in agent_end; in execute mode the
		// currentMode check already prevents it, but frozenTodoList adds a
		// safety net for any future code path that may skip the mode check.
		frozenTodoList = true;
		const first = todoItems[0];
		pi.sendMessage(
			{
				customType: "workflow-execute-start",
				content: `Execute the plan. Start with step 1: ${first.text}`,
				display: true,
			},
			{ triggerTurn: true },
		);
	}

	// ── step Tool ──────────────────────────────────────────────────────────────
	pi.registerTool({
		name: "step",
		label: "Step",
		description:
			"Track progress of individual plan steps during execution. Call with status='in_progress' when you start a step, 'completed' when finished, or 'blocked' if you need human input.",
		parameters: Type.Object({
			id: Type.Number({ description: "The step number to update" }),
			status: StringEnum(["in_progress", "completed", "blocked"] as const, {
				description: "New status for the step",
			}),
		}),

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const item = todoItems.find((t) => t.step === params.id);
			if (!item) {
				return {
					content: [{ type: "text", text: `Step ${params.id} not found in the current plan.` }],
				};
			}

			// Silent self-healing: if another step is in_progress, reset it
			if (params.status === "in_progress") {
				for (const t of todoItems) {
					if (t.step !== params.id && t.status === "in_progress") {
						t.status = "pending";
					}
				}
			}

			item.status = params.status;

			// Recalculate budget after status change
			relaunchBudget = calculateBudget();

			updateStatus(ctx);
			persistState();

			// Build status output
			const statusIcon = (t: TodoItem) => {
				if (t.status === "completed") return "✓";
				if (t.status === "in_progress") return "→";
				if (t.status === "blocked") return "⚠";
				return " ";
			};
			const allSteps = todoItems.map((t) => `${t.step}. [${statusIcon(t)}] ${t.text}`).join("\n");

			return {
				content: [
					{
						type: "text",
						text: `Step ${params.id} marked as ${params.status}.\n\nPlan status:\n${allSteps}`,
					},
				],
				details: { todos: [...todoItems], relaunchBudget },
			};
		},

		renderCall(args, theme) {
			const icon =
				args.status === "completed" ? "✓" : args.status === "in_progress" ? "→" : "⚠";
			const color = args.status === "completed" ? "success" : args.status === "in_progress" ? "accent" : "warning";
			return new Text(
				theme.fg("toolTitle", theme.bold("step ")) + theme.fg(color, icon) + " " + theme.fg("muted", `step ${args.id}`),
				0, 0,
			);
		},

		renderResult(result, _opts, theme) {
			const details = result.details as { todos: TodoItem[]; relaunchBudget?: number } | undefined;
			if (!details?.todos) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}
			const completed = details.todos.filter((t) => t.status === "completed").length;
			const total = details.todos.length;
			let out = theme.fg("muted", `${completed}/${total} steps done`);
			if (details.relaunchBudget !== undefined) {
				out += " " + theme.fg("dim", `(${details.relaunchBudget} relaunches)`);
			}
			out += "\n";
			for (const t of details.todos) {
				const icon =
					t.status === "completed"
						? theme.fg("success", "✓")
						: t.status === "in_progress"
							? theme.fg("accent", "→")
							: t.status === "blocked"
								? theme.fg("warning", "⚠")
								: theme.fg("dim", " ");
				const label =
					t.status === "completed"
						? theme.fg("dim", theme.strikethrough(t.text))
						: t.status === "in_progress"
							? theme.fg("text", t.text)
							: t.status === "blocked"
								? theme.fg("warning", t.text)
								: theme.fg("muted", t.text);
				out += `\n ${icon} ${theme.fg("dim", String(t.step))}. ${label}`;
			}
			return new Text(out, 0, 0);
		},
	});

	// ── Commands ──────────────────────────────────────────────────────────────
	pi.registerCommand("think", {
		description: "Enter think mode (free-form dialogue)",
		handler: async (_args, ctx) => {
			abortExecution();
			setMode("think", ctx);
			ctx.ui.notify("Think mode — free-form exploration");
		},
	});

	pi.registerCommand("plan", {
		description: "Enter plan mode (read-only, produce numbered plan)",
		handler: async (_args, ctx) => {
			abortExecution();
			setMode("plan", ctx);
			ctx.ui.notify("Plan mode — read-only exploration");
		},
	});

	pi.registerCommand("execute", {
		description: "Enter execute mode (run the plan)",
		handler: async (_args, ctx) => {
			if (todoItems.length === 0) {
				ctx.ui.notify("No plan found. Create a plan first in plan mode.", "warning");
				return;
			}
			ctx.ui.notify(`Execute mode — ${todoItems.length} steps, ${calculateBudget()} relaunches`);
			startExecution(ctx);
		},
	});

	pi.registerCommand("full", {
		description: "Enter full mode (all tools enabled)",
		handler: async (_args, ctx) => {
			abortExecution();
			setMode("full", ctx);
			ctx.ui.notify("Full mode — all tools enabled");
		},
	});

	// ── Shortcuts ──────────────────────────────────────────────────────────────
	pi.registerShortcut(Key.alt("j"), {
		description: "Enter think mode",
		handler: async (ctx) => {
			abortExecution();
			setMode("think", ctx);
		},
	});

	pi.registerShortcut(Key.alt("k"), {
		description: "Enter plan mode",
		handler: async (ctx) => {
			abortExecution();
			setMode("plan", ctx);
		},
	});

	pi.registerShortcut(Key.alt("l"), {
		description: "Enter execute mode",
		handler: async (ctx) => {
			if (todoItems.length === 0) {
				ctx.ui.notify("No plan found. Create a plan first in plan mode.", "warning");
				return;
			}
			setMode("execute", ctx);
			startExecution(ctx);
		},
	});

	pi.registerShortcut(Key.alt("h"), {
		description: "Enter full mode",
		handler: async (ctx) => {
			abortExecution();
			setMode("full", ctx);
		},
	});


	// ── Flags ──────────────────────────────────────────────────────────────────
	pi.registerFlag("think-mode", {
		description: "Start in think mode",
		type: "boolean",
		default: false,
	});

	// plan-mode flag is registered for discoverability and symmetry with --think-mode / --full-mode.
	pi.registerFlag("plan-mode", {
		description: "Start in plan mode",
		type: "boolean",
		default: false,
	});

	pi.registerFlag("full-mode", {
		description: "Start in full mode",
		type: "boolean",
		default: false,
	});

	// ── Bash Guard ─────────────────────────────────────────────────────────────
	pi.on("tool_call", async (event) => {
		if (event.toolName !== "bash") return;
		if (currentMode !== "think" && currentMode !== "plan") return;

		const command = event.input.command as string;
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `${currentMode} mode: command blocked (not allowlisted).\nCommand: ${command}`,
			};
		}
	});

	// ── Context Injection ──────────────────────────────────────────────────────
	pi.on("before_agent_start", async () => {
		// No injection in full mode
		if (currentMode === "full") return undefined;

		if (currentMode === "think") {
			return {
				message: {
					customType: "workflow-think-context",
					content: `You are in think mode — a free-form space to help the user clarify their ideas before committing to a plan.

**Inspect the codebase with read, bash, grep, find, ls. Check system tool behaviour with man, apropos, and --help. Use websearch and webfetch to ground your reasoning in current docs, benchmarks, changelogs, or prior art. Do not rely on what you already know if any of these can't verify it.**

- You can only use: read, bash, grep, find, ls,  websearch, webfetch
- Ask questions, surface assumptions, explore trade-offs
- Be direct and assertive — if an idea is flawed, say so and explain why; do not validate ideas just to be agreeable
- Push back when something doesn't make sense
- Do NOT produce a numbered plan that comes in plan mode
- Do NOT try to modify files, you can't. All write and edit tools are disabled.`,
					display: false,
				},
			};
		}

		if (currentMode === "plan") {
			return {
				message: {
					customType: "workflow-plan-context",
					content: `You are in plan mode — read-only exploration for safe code analysis.

**CRITICAL: You are in a SAFE, READ-ONLY environment. File modifications are DISABLED. Your plan must be executable in execute mode with ONLY the tools available there.**

**Before writing any step that depends on a library, API, or tool — gather evidence first:**
- Inspect the codebase with read, grep, find, ls
- Check system tool behaviour with man, apropos, --help
- Use websearch and webfetch to verify current docs, correct versions, and API signatures
- A plan built on stale assumptions will FAIL at execution time

**AVAILABLE TOOLS (read-only only):**
- read, grep, find, ls, websearch, webfetch
- bash (RESTRICTED — see below)

**DISABLED TOOLS (will cause errors):**
- edit, write — file modifications are NOT allowed in plan mode

**BASH COMMAND RESTRICTIONS (enforced by system):**
- Only allowlisted read-only commands are permitted
- Use \`gawk --sandbox\` instead of \`awk\` (disables file writes and system())
- Use the \`read\` tool instead of vim, nano, emacs, or code
- Commands like \`rm\`, \`mv\`, \`cp\` (without --no-clobber), \`chmod\` etc. will be BLOCKED by the bash guard

**REQUIRED OUTPUT:**
Once you have gathered all necessary information, produce a detailed numbered plan under a \`Plan:\` header:

\`\`\`
Plan:
1. First step description
2. Second step description
3. Third step description
\`\`\`

**RULES:**
- Do NOT attempt to make any changes — only describe what you would do
- Do NOT include information gathering steps in the plan
- Do NOT reference tools that won't be available in execute mode
- Ensure all steps use ONLY the tools listed above
- If anything is unclear, ask clarifying questions BEFORE producing the plan
- Do NOT make assumptions about file contents, API signatures, or tool behavior`,
					display: false,
				},
			};
		}
		if (currentMode === "execute") {
			const statusIcon = (t: TodoItem) => {
				if (t.status === "completed") return "✓ completed";
				if (t.status === "in_progress") return "→ in_progress";
				if (t.status === "blocked") return "⚠ blocked";
				return "  pending";
			};
			const allSteps = todoItems.map((t) => `${t.step}. [${statusIcon(t)}] ${t.text}`).join("\n");
			const remaining = todoItems.filter((t) => t.status !== "completed");
			const nextStep = remaining.length > 0 ? `${remaining[0].step}. ${remaining[0].text}` : "All steps complete";

			return {
				message: {
					customType: "workflow-execute-context",
					content: `You are executing the plan. Full tool access is enabled.

Use the \`step\` tool to track progress:
- Call \`step({ id, status: "in_progress" })\` when you start a step
- Call \`step({ id, status: "completed" })\` when you finish a step
- Only one step may be in_progress at a time

If you are blocked and need human input:
2. CALL \`step({ id, status: "blocked" })\` on the current step
3. STOP — do not proceed further

Work through steps in order. Do not skip steps.

Original plan:
${originalPlanText || "(no original plan text)"}

Current step statuses:
${allSteps}

Next step: ${nextStep}

Do NOT forget to use the \`step\` tool to track progress:
- Call \`step({ id, status: "in_progress" })\` BEFORE you start a step
- Call \`step({ id, status: "completed" })\` AFTER you finish a step
- Only one step may be in_progress at a time
- Execute the steps in order unless something prevents you to do so`,
					display: false,
				},
			};
		}

		return undefined;
	});

	// ── Context Filtering ──────────────────────────────────────────────────────

	/**
	 * Strip hidden context messages that belong to a mode other than `activeMode`.
	 * Called on every context event so stale injections don't bleed across mode switches.
	 */
	function filterContextMessages(messages: AgentMessage[], activeMode: WorkflowMode): AgentMessage[] {
		return messages.filter((m) => {
			const msg = m as AgentMessage & { customType?: string };

			// Strip think context when not in think mode
			if (activeMode !== "think" && msg.customType === "workflow-think-context") return false;

			// Strip plan context when not in plan mode
			if (activeMode !== "plan" && msg.customType === "workflow-plan-context") return false;

			// Strip execute context when not in execute mode
			if (activeMode !== "execute" && msg.customType === "workflow-execute-context") return false;

			return true;
		});
	}

	// ── agent_end Handler ──────────────────────────────────────────────────────
	pi.on("agent_end", async (event, ctx) => {
		// In plan mode: extract todos from the last assistant message
		if (currentMode === "plan" && !frozenTodoList) {
			const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
			if (lastAssistant) {
				const extracted = extractTodoItems(getTextContent(lastAssistant));
				if (extracted.length > 0) {
					todoItems = extracted;
					originalPlanText = getTextContent(lastAssistant);
					persistState();
				}
			}
		}

		// Only handle relaunch logic in execute mode
		if (currentMode !== "execute") return;

		// Check if all steps completed or all remaining steps are blocked
		const allDone = todoItems.every((t) => t.status === "completed");
		const remaining = todoItems.filter((t) => t.status !== "completed");
		const allRemainingBlocked = remaining.length > 0 && remaining.every((t) => t.status === "blocked");
		if (allDone || allRemainingBlocked) {
			const completedList = todoItems.map((t) => `✓ ${t.text}`).join("\n");
			const blockedList = remaining.filter((t) => t.status === "blocked").map((t) => `⚠ ${t.text}`).join("\n");
			const message = allDone
				? `**Plan Complete!** ✓\n\n${completedList}`
				: `**Execution Blocked** ⚠\n\n${completedList}\n\n${blockedList}\n\nAll remaining steps are blocked.`;
			pi.sendMessage(
				{ customType: allDone ? "workflow-complete" : "workflow-blocked", content: message, display: true },
				{ triggerTurn: false }
			);
			setMode("plan", ctx);
			ctx.ui.notify(allDone ? "Plan execution complete!" : "Execution blocked — all remaining steps need human input");
			return;
		}

		// Consume one relaunch slot
		relaunchBudget--;

		// Check if we can relaunch
		if (relaunchBudget >= 0) {
			const remaining = todoItems.filter((t) => t.status !== "completed");
			pi.sendMessage(
				{
					customType: "workflow-relaunch",
					content: `Continue executing the plan.\n\nRemaining relaunches: ${relaunchBudget} (this turn uses 1 slot).\n\n${remaining.length} step(s) remaining.\n\nIf blocked: mark the step blocked with \`step({ id, status: "blocked" })\`, and stop working.`,
					display: true,
				},
				{ triggerTurn: true }
			);
		} else {
			// Budget exhausted
			pi.sendMessage(
				{
					customType: "workflow-exhausted",
					content: `Relaunch budget exhausted. ${todoItems.filter((t) => t.status !== "completed").length} step(s) remaining.`,
					display: true,
				},
				{ triggerTurn: false }
			);
			setMode("plan", ctx);
			ctx.ui.notify("Execution paused — budget exhausted", "warning");
		}
	});

	// ── questionnaire Answer Handler ───────────────────────────────────────────
	// When the user sends a message while in execute mode and the last tool was
	// a questionnaire, recalculate the relaunch budget and relaunch.
	pi.on("input", async (event, ctx) => {
		if (event.source !== "interactive") return;
		if (currentMode !== "execute") return;

		// Recalculate budget
		relaunchBudget = calculateBudget();
		updateStatus(ctx);
		persistState();
	});

	// ── Context Events ─────────────────────────────────────────────────────────
	pi.on("context", async (event) => {
		const filtered = filterContextMessages(event.messages as AgentMessage[], currentMode);
		if (filtered.length !== event.messages.length) {
			return { messages: filtered };
		}
		return undefined;
	});

	// ── Initialization ──────────────────────────────────────────────────────────

	/**
	 * Reset and configure workflow state for a new or resumed session.
	 *
	 * @param forNewSession - true when the user creates a brand-new session (/new).
	 *   Flags are applied as the starting mode and no persisted state is restored.
	 *   false on process start and /resume: startup flags set the baseline, then
	 *   any persisted workflow entry overrides them.
	 */
	function initializeState(ctx: ExtensionContext, forNewSession: boolean): void {
		todoItems = [];
		relaunchBudget = 0;
		originalPlanText = "";
		frozenTodoList = false;

		// Startup flags set the baseline mode; think is the default.
		if (pi.getFlag("think-mode")) {
			currentMode = "think";
		} else if (pi.getFlag("full-mode")) {
			currentMode = "full";
		} else if (pi.getFlag("plan-mode")) {
			currentMode = "plan";
		} else {
			currentMode = "think";
		}

		if (!forNewSession) {
			// session_start or /resume: restore from persisted state (overrides flags).
			const entries = ctx.sessionManager.getEntries();
			const workflowEntry = entries
				.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === PERSIST_KEY)
				.pop() as
				| { data?: { mode: WorkflowMode; todoItems: TodoItem[]; relaunchBudget: number; originalPlanText: string } }
				| undefined;

			if (workflowEntry?.data) {
				currentMode = workflowEntry.data.mode ?? currentMode;
				todoItems = workflowEntry.data.todoItems ?? [];
				relaunchBudget = workflowEntry.data.relaunchBudget ?? 0;
				originalPlanText = workflowEntry.data.originalPlanText ?? "";

				// If resuming in execute mode, freeze the todo list
				if (currentMode === "execute") {
					frozenTodoList = true;
				}
			}

			// Replay step tool results to reconstruct step statuses
			if (currentMode === "execute" && todoItems.length > 0) {
				for (const entry of entries) {
					if (entry.type !== "message" || !("message" in entry)) continue;
					const msg = entry.message as AgentMessage & { toolName?: string; details?: unknown };
					if (msg.role !== "tool_result" || msg.toolName !== "step") continue;
					const details = msg.details as { todos?: TodoItem[] } | undefined;
					if (details?.todos) {
						for (const snap of details.todos) {
							const item = todoItems.find((t) => t.step === snap.step);
							if (item) item.status = snap.status;
						}
					}
				}
			}
		}

		// Apply tool set
		switch (currentMode) {
			case "think":
			case "plan":
				pi.setActiveTools(READ_ONLY_TOOLS);
				break;
			case "execute":
				pi.setActiveTools(EXECUTE_TOOLS);
				break;
			case "full":
				pi.setActiveTools(FULL_TOOLS);
				break;
		}

		updateStatus(ctx);
	}

	// Session start / resume
	pi.on("session_start", async (_event, ctx) => {
		initializeState(ctx, false);
	});

	pi.on("session_switch", async (event, ctx) => {
		initializeState(ctx, event.reason === "new");
	});

}
