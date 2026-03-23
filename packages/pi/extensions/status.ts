/**
 * Status Bar Extension
 *
 * Standalone helper module for the workflow extension's status bar and widget.
 * Import the exported functions directly — no pi API needed at call sites.
 *
 * Usage:
 *   import { setStatus, clearStatus, setTodoWidget, clearTodoWidget } from "./status.js";
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

/** Status bar region key used for workflow mode display. */
export const STATUS_REGION = "workflow-mode";

/** Widget key used for the todo list panel during execute mode. */
export const WIDGET_ID = "workflow-todos";

export type WorkflowMode = "think" | "plan" | "execute" | "full";

export interface StatusOptions {
	theme: ExtensionContext["ui"]["theme"];
	completedSteps?: number;
	totalSteps?: number;
	relaunchBudget?: number;
}

/**
 * Set the workflow-mode status bar text to match the given mode.
 * In execute mode, shows step progress and remaining relaunch budget.
 */
export function setStatus(mode: WorkflowMode, options: StatusOptions, ctx: ExtensionContext): void {
	const { theme, completedSteps = 0, totalSteps = 0, relaunchBudget = 0 } = options;

	if (!ctx.hasUI) return;

	if (mode === "think") {
		ctx.ui.setStatus(STATUS_REGION, theme.fg("muted", "Think"));
	} else if (mode === "plan") {
		ctx.ui.setStatus(STATUS_REGION, theme.fg("warning", "Plan"));
	} else if (mode === "execute") {
		const text = `Executing ${completedSteps}/${totalSteps} (${relaunchBudget} relaunches)`;
		ctx.ui.setStatus(STATUS_REGION, theme.fg("accent", text));
	} else if (mode === "full") {
		ctx.ui.setStatus(STATUS_REGION, theme.fg("success", "Full"));
	}
}

/**
 * Clear the workflow-mode entry from the status bar.
 */
export function clearStatus(ctx: ExtensionContext): void {
	if (ctx.hasUI) {
		ctx.ui.setStatus(STATUS_REGION, undefined);
	}
}

/**
 * Render the todo list as a widget panel.
 * Replaces any existing widget content; pass an empty array to clear.
 */
export function setTodoWidget(todos: Array<{ step: number; text: string; status: string }>, ctx: ExtensionContext): void {
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

/**
 * Remove the todo list widget panel.
 */
export function clearTodoWidget(ctx: ExtensionContext): void {
	if (ctx.hasUI) {
		ctx.ui.setWidget(WIDGET_ID, undefined);
	}
}

/**
 * Required default export to satisfy pi's extension loader.
 * All functionality is exposed through the named exports above.
 */
export default function statusExtension(_pi: ExtensionAPI): void {}
