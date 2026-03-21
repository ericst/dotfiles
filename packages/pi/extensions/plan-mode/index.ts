/**
 * Plan Mode Extension
 *
 * Read-only exploration mode for safe code analysis.
 * When enabled, only read-only tools are available.
 *
 * Features:
 * - Starts in plan mode by default (pass --no-plan to disable)
 * - /plan command or Ctrl+Alt+P to toggle
 * - Bash restricted to allowlisted read-only commands
 * - Extracts numbered plan steps from "Plan:" sections
 * - plan_todo tool call to mark steps in_progress / completed during execution
 * - Progress tracking widget during execution
 */

import type { AgentMessage } from "@mariozechner/pi-agent-core";
import { StringEnum } from "@mariozechner/pi-ai";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key, Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { extractTodoItems, isSafeCommand, type TodoItem } from "./utils.js";

// Tools
const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls", "questionnaire"];
const NORMAL_MODE_TOOLS = ["read", "bash", "edit", "write"];
const EXECUTION_MODE_TOOLS = ["read", "bash", "edit", "write", "plan_todo"];

// Type guard for assistant messages
function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
	return m.role === "assistant" && Array.isArray(m.content);
}

// Extract text content from an assistant message
function getTextContent(message: AssistantMessage): string {
	return message.content
		.filter((block): block is TextContent => block.type === "text")
		.map((block) => block.text)
		.join("\n");
}

export default function planModeExtension(pi: ExtensionAPI): void {
	let planModeEnabled = false;
	let executionMode = false;
	let todoItems: TodoItem[] = [];
	let originalPlanText = "";

	pi.registerFlag("plan", {
		description: "Start in plan mode (default: on; pass --no-plan to disable)",
		type: "boolean",
		default: true,
	});

	// plan_todo tool — available during execution mode only
	pi.registerTool({
		name: "plan_todo",
		label: "Plan Todo",
		description:
			"Update the status of a plan step during build/execution mode. Call with status='in_progress' when you start a step, and status='completed' when you finish it. Only one step may be 'in_progress' at a time — mark the current step 'completed' before starting the next one.",
		parameters: Type.Object({
			id: Type.Number({ description: "The step number to update (as shown in the plan)" }),
			status: StringEnum(["in_progress", "completed"] as const, {
				description: "New status for the step. Only one step may be 'in_progress' at a time.",
			}),
		}),

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const item = todoItems.find((t) => t.step === params.id);
			if (!item) {
				return {
					content: [{ type: "text", text: `Step ${params.id} not found in the current plan.` }],
				};
			}

			// Enforce: only one step may be in_progress at a time
			if (params.status === "in_progress") {
				const alreadyActive = todoItems.find((t) => t.step !== params.id && t.status === "in_progress");
				if (alreadyActive) {
					return {
						content: [
							{
								type: "text",
								text: `Cannot mark step ${params.id} as in_progress: step ${alreadyActive.step} ("${alreadyActive.text}") is already in progress. Mark it 'completed' before starting a new step.`,
							},
						],
					};
				}
			}

			item.status = params.status;
			updateStatus(ctx);
			persistState();

			const statusLine = (t: TodoItem) => {
				const icon = t.status === "completed" ? "✓" : t.status === "in_progress" ? "→" : " ";
				return `${t.step}. [${icon}] ${t.text}`;
			};
			const allSteps = todoItems.map(statusLine).join("\n");
			return {
				content: [
					{
						type: "text",
						text: `Step ${params.id} marked as ${params.status}.\n\nPlan status:\n${allSteps}`,
					},
				],
				details: { todos: [...todoItems] },
			};
		},

		renderCall(args, theme) {
			const statusColor = args.status === "completed" ? "success" : "accent";
			const icon = args.status === "completed" ? "✓" : "→";
			return new Text(
				theme.fg("toolTitle", theme.bold("plan_todo ")) +
					theme.fg(statusColor, icon) +
					" " +
					theme.fg("muted", `step ${args.id}`),
				0,
				0,
			);
		},

		renderResult(result, _opts, theme) {
			const details = result.details as { todos: TodoItem[] } | undefined;
			if (!details?.todos) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "", 0, 0);
			}
			const completed = details.todos.filter((t) => t.status === "completed").length;
			const total = details.todos.length;
			let out = theme.fg("muted", `${completed}/${total} steps done`);
			for (const t of details.todos) {
				const icon =
					t.status === "completed"
						? theme.fg("success", "✓")
						: t.status === "in_progress"
							? theme.fg("accent", "→")
							: theme.fg("dim", " ");
				const label =
					t.status === "completed"
						? theme.fg("dim", theme.strikethrough(t.text))
						: t.status === "in_progress"
							? theme.fg("text", t.text)
							: theme.fg("muted", t.text);
				out += `\n ${icon} ${theme.fg("dim", String(t.step))}. ${label}`;
			}
			return new Text(out, 0, 0);
		},
	});

	function updateStatus(ctx: ExtensionContext): void {
		// Footer status
		if (executionMode && todoItems.length > 0) {
			const completed = todoItems.filter((t) => t.status === "completed").length;
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("accent", `Build ${completed}/${todoItems.length}`));
		} else if (planModeEnabled) {
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("warning", "Plan"));
		} else {
			ctx.ui.setStatus("plan-mode", undefined);
		}

		// Widget showing todo list
		if (executionMode && todoItems.length > 0) {
			const lines = todoItems.map((item) => {
				if (item.status === "completed") {
					return (
						ctx.ui.theme.fg("success", "☑ ") + ctx.ui.theme.fg("muted", ctx.ui.theme.strikethrough(item.text))
					);
				}
				if (item.status === "in_progress") {
					return ctx.ui.theme.fg("accent", "▶ ") + ctx.ui.theme.fg("text", item.text);
				}
				return `${ctx.ui.theme.fg("dim", "☐ ")}${ctx.ui.theme.fg("muted", item.text)}`;
			});
			ctx.ui.setWidget("plan-todos", lines);
		} else {
			ctx.ui.setWidget("plan-todos", undefined);
		}
	}

	function togglePlanMode(ctx: ExtensionContext): void {
		planModeEnabled = !planModeEnabled;
		executionMode = false;
		todoItems = [];
		originalPlanText = "";

		if (planModeEnabled) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
			ctx.ui.notify(`Plan mode enabled. Tools: ${PLAN_MODE_TOOLS.join(", ")}`);
		} else {
			pi.setActiveTools(NORMAL_MODE_TOOLS);
			ctx.ui.notify("Plan mode disabled. Full access restored.");
		}
		updateStatus(ctx);
	}

	function persistState(): void {
		pi.appendEntry("plan-mode", {
			enabled: planModeEnabled,
			todos: todoItems,
			executing: executionMode,
			originalPlanText,
		});
	}

	pi.registerCommand("plan", {
		description: "Toggle plan mode (read-only exploration)",
		handler: async (_args, ctx) => togglePlanMode(ctx),
	});

	pi.registerCommand("todos", {
		description: "Show current plan todo list",
		handler: async (_args, ctx) => {
			if (todoItems.length === 0) {
				ctx.ui.notify("No todos. Create a plan first with /plan", "info");
				return;
			}
			const icon = (s: TodoItem["status"]) => (s === "completed" ? "✓" : s === "in_progress" ? "→" : "○");
			const list = todoItems.map((item, i) => `${i + 1}. ${icon(item.status)} ${item.text}`).join("\n");
			ctx.ui.notify(`Plan Progress:\n${list}`, "info");
		},
	});

	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle plan mode",
		handler: async (ctx) => togglePlanMode(ctx),
	});

	// Block destructive bash commands in plan mode
	pi.on("tool_call", async (event) => {
		if (!planModeEnabled || event.toolName !== "bash") return;

		const command = event.input.command as string;
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `Plan mode: command blocked (not allowlisted). Use /plan to disable plan mode first.\nCommand: ${command}`,
			};
		}
	});

	// Filter out stale plan mode context when not in plan mode
	pi.on("context", async (event) => {
		if (planModeEnabled) return;

		return {
			messages: event.messages.filter((m) => {
				const msg = m as AgentMessage & { customType?: string };
				if (msg.customType === "plan-mode-context") return false;
				if (msg.role !== "user") return true;

				const content = msg.content;
				if (typeof content === "string") {
					return !content.includes("[PLAN MODE ACTIVE]");
				}
				if (Array.isArray(content)) {
					return !content.some(
						(c) => c.type === "text" && (c as TextContent).text?.includes("[PLAN MODE ACTIVE]"),
					);
				}
				return true;
			}),
		};
	});

	// Inject plan/execution context before agent starts
	pi.on("before_agent_start", async () => {
		if (planModeEnabled) {
			return {
				message: {
					customType: "plan-mode-context",
					content: `[PLAN MODE ACTIVE]
You are in plan mode - a read-only exploration mode for safe code analysis.

Restrictions:
- You can only use: read, bash, grep, find, ls, questionnaire
- You CANNOT use: edit, write (file modifications are disabled)
- Bash is restricted to an allowlist of read-only commands

Safe alternatives for commonly blocked commands:
- awk        → use 'gawk --sandbox' (disables all file writes, pipes and system() at runtime)
- vim/nano/emacs/code → use the 'read' tool instead to inspect file contents

Ask clarifying questions using the questionnaire tool.

Create a detailed numbered plan under a "Plan:" header:

Plan:
1. First step description
2. Second step description
...

Do NOT attempt to make changes - just describe what you would do.`,
					display: false,
				},
			};
		}

		if (executionMode && todoItems.length > 0) {
			const statusIcon = (t: TodoItem) =>
				t.status === "completed" ? "✓ completed " : t.status === "in_progress" ? "→ in_progress" : "  pending  ";
			const allSteps = todoItems.map((t) => `${t.step}. [${statusIcon(t)}] ${t.text}`).join("\n");
			const remaining = todoItems.filter((t) => t.status !== "completed");
			return {
				message: {
					customType: "plan-execution-context",
					content: `[EXECUTING PLAN - Full tool access enabled]

${originalPlanText ? `Original plan:\n${originalPlanText}\n\n` : ""}Plan step status:
${allSteps}

${remaining.length === 0 ? "All steps are complete!" : `Next step to work on: ${remaining[0].step}. ${remaining[0].text}`}

Instructions:
- When you START a step, call: plan_todo({ id: <step>, status: "in_progress" })
- When you FINISH a step, call: plan_todo({ id: <step>, status: "completed" })
- Work through steps in order. Only one step in_progress at a time.`,
					display: false,
				},
			};
		}
	});

	// Handle plan completion and plan mode UI
	pi.on("agent_end", async (event, ctx) => {
		// ── Execution mode: check progress ──────────────────────────────────────
		if (executionMode && todoItems.length > 0) {
			const allDone = todoItems.every((t) => t.status === "completed");

			if (allDone) {
				const completedList = todoItems.map((t) => `~~${t.text}~~`).join("\n");
				pi.sendMessage(
					{ customType: "plan-complete", content: `**Plan Complete!** ✓\n\n${completedList}`, display: true },
					{ triggerTurn: false },
				);
				executionMode = false;
				todoItems = [];
				originalPlanText = "";
				planModeEnabled = true;
				pi.setActiveTools(PLAN_MODE_TOOLS);
				updateStatus(ctx);
				persistState();
				return;
			}

			// Some steps still incomplete — ask user whether to relaunch
			const remaining = todoItems.filter((t) => t.status !== "completed");
			const choice = await ctx.ui.select(
				`${remaining.length} step(s) not yet completed. Continue?`,
				["Relaunch", "Stop"],
			);

			if (choice === "Relaunch") {
				const statusIcon = (t: TodoItem) =>
					t.status === "completed" ? "✓ completed " : t.status === "in_progress" ? "→ in_progress" : "  pending  ";
				const allSteps = todoItems.map((t) => `${t.step}. [${statusIcon(t)}] ${t.text}`).join("\n");
				const relaunchContent = `Continue executing the plan. Here is the current status of every step:

${allSteps}

For each step that is NOT yet marked completed:
        - If the work was already done in your previous run but you forgot to call plan_todo, call plan_todo({ id: <step>, status: "completed" }) to mark it as so.
        - If the work is marked as in progress but not finished, complete the work, then call plan_todo({ id: <step>, status: "completed" }).
        - If the work was NOT done and not started then do the following:
           - First call plan_todo({ id: <step>, status: "in_progress" }) to mark it started.
           - Do the work.
           - Last call plan_todo({ id: <step>, status: "completed" }).

Remember, one-step in_progress at the time.`;
				pi.sendMessage(
					{ customType: "plan-relaunch", content: relaunchContent, display: true },
					{ triggerTurn: true },
				);
			} else {
				// User chose to stop — exit execution mode cleanly
				executionMode = false;
				todoItems = [];
				originalPlanText = "";
				planModeEnabled = true;
				pi.setActiveTools(PLAN_MODE_TOOLS);
				updateStatus(ctx);
				persistState();
			}
			return;
		}

		// ── Plan mode: post-planning prompt ─────────────────────────────────────
		if (!planModeEnabled || !ctx.hasUI) return;

		// Extract todos from last assistant message
		const lastAssistant = [...event.messages].reverse().find(isAssistantMessage);
		if (lastAssistant) {
			const extracted = extractTodoItems(getTextContent(lastAssistant));
			if (extracted.length > 0) {
				todoItems = extracted;
			}
		}

		// Show plan steps and prompt for next action
		if (todoItems.length > 0) {
			const todoListText = todoItems.map((t) => `${t.step}. ☐ ${t.text}`).join("\n");
			pi.sendMessage(
				{
					customType: "plan-todo-list",
					content: `**Plan Steps (${todoItems.length}):**\n\n${todoListText}`,
					display: true,
				},
				{ triggerTurn: false },
			);
		}

		const choice = await ctx.ui.select("Plan mode - what next?", [
			todoItems.length > 0 ? "Execute the plan (track progress)" : "Execute the plan",
			"Stay in plan mode",
			"Refine the plan",
		]);

		if (choice?.startsWith("Execute")) {
			// Capture the full plan text for context injection during execution
			if (lastAssistant) {
				originalPlanText = getTextContent(lastAssistant);
			}
			planModeEnabled = false;
			executionMode = todoItems.length > 0;
			pi.setActiveTools(EXECUTION_MODE_TOOLS);
			updateStatus(ctx);

			const execMessage =
				todoItems.length > 0
					? `Execute the plan. Start with: ${todoItems[0].text}`
					: "Execute the plan you just created.";
			pi.sendMessage(
				{ customType: "plan-mode-execute", content: execMessage, display: true },
				{ triggerTurn: true },
			);
		} else if (choice === "Refine the plan") {
			const refinement = await ctx.ui.editor("Refine the plan:", "");
			if (refinement?.trim()) {
				pi.sendUserMessage(refinement.trim());
			}
		}
	});

	// Shared initialisation logic for both session_start and session_switch.
	// - forNewSession: true  → reset everything and apply the --plan flag (no entries to restore)
	//                  false → restore persisted state from the session's entries
	function initializeState(ctx: ExtensionContext, forNewSession: boolean): void {
		// Reset in-memory state first
		planModeEnabled = false;
		executionMode = false;
		todoItems = [];
		originalPlanText = "";

		if (forNewSession) {
			// Brand-new session: honour the --plan flag (default: true)
			if (pi.getFlag("plan") !== false) {
				planModeEnabled = true;
			}
		} else {
			// Process start or /resume: restore from persisted entries
			const entries = ctx.sessionManager.getEntries();

			// Apply --plan flag baseline before consulting persisted state
			if (pi.getFlag("plan") !== false) {
				planModeEnabled = true;
			}

			// Restore persisted state (overrides the flag baseline)
			const planModeEntry = entries
				.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "plan-mode")
				.pop() as
				| { data?: { enabled: boolean; todos?: TodoItem[]; executing?: boolean; originalPlanText?: string } }
				| undefined;

			if (planModeEntry?.data) {
				planModeEnabled = planModeEntry.data.enabled ?? planModeEnabled;
				todoItems = planModeEntry.data.todos ?? todoItems;
				executionMode = planModeEntry.data.executing ?? executionMode;
				originalPlanText = planModeEntry.data.originalPlanText ?? originalPlanText;
			}

			// On resume: replay plan_todo tool results to reconstruct step statuses.
			// The last tool result for each step wins, so we simply apply them in order.
			if (executionMode && todoItems.length > 0) {
				for (const entry of entries) {
					if (entry.type !== "message" || !("message" in entry)) continue;
					const msg = entry.message as AgentMessage & { toolName?: string; details?: unknown };
					if (msg.role !== "toolResult" || msg.toolName !== "plan_todo") continue;
					const details = msg.details as { todos?: TodoItem[] } | undefined;
					if (details?.todos) {
						// Replace statuses from the snapshot; keep step/text from our in-memory list
						// in case the snapshot is from a different plan version.
						for (const snap of details.todos) {
							const item = todoItems.find((t) => t.step === snap.step);
							if (item) item.status = snap.status;
						}
					}
				}
			}
		}

		if (planModeEnabled) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
		} else if (executionMode) {
			pi.setActiveTools(EXECUTION_MODE_TOOLS);
		} else {
			pi.setActiveTools(NORMAL_MODE_TOOLS);
		}
		updateStatus(ctx);
	}

	// Initial process start
	pi.on("session_start", async (_event, ctx) => {
		initializeState(ctx, false);
	});

	// /new → reset to plan mode; /resume → restore persisted state
	pi.on("session_switch", async (event, ctx) => {
		initializeState(ctx, event.reason === "new");
	});
}
