/**
 * Status Bar Extension
 *
 * Standalone helper module for the workflow extension's status bar.
 * Import the exported functions directly — no pi API needed at call sites.
 *
 * Usage:
 *   import { setStatus, clearStatus } from "./status.js";
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

/** Status bar region key used for workflow mode display. */
export const STATUS_REGION = "workflow-mode";

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
		ctx.ui.setStatus(STATUS_REGION, theme.fg("warning", "Think"));
	} else if (mode === "plan") {
		ctx.ui.setStatus(STATUS_REGION, theme.fg("warning", "Plan"));
	} else if (mode === "execute") {
		const text = `Executing ${completedSteps}/${totalSteps} (${relaunchBudget} relaunches)`;
		ctx.ui.setStatus(STATUS_REGION, theme.fg("warning", text));
	} else if (mode === "full") {
		ctx.ui.setStatus(STATUS_REGION, theme.fg("warning", "Full"));
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
 * Required default export to satisfy pi's extension loader.
 * All functionality is exposed through the named exports above.
 */
export default function statusExtension(_pi: ExtensionAPI): void {}
