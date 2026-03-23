/**
 * Status Bar Extension
 *
 * Standalone helper module shared by the workflow and sandbox extensions for
 * status-bar management. Import the exported functions directly — no pi API
 * needed at call sites.
 *
 * Usage:
 *   import { setStatus, clearStatus } from "./status.js";
 *   import { setSandboxStatus } from "./status.js";
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

/** Status bar region key used for workflow mode display. */
export const STATUS_REGION = "workflow-mode";

/** Status bar region key for sandbox state (sorts after workflow-mode). */
export const SANDBOX_STATUS_REGION = "workflow-sandbox";

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

/** Sandbox operating mode for the status bar. */
export type SandboxStatusMode = "full" | "filesystem" | "disabled";

/** Display labels for each sandbox mode. */
export const SANDBOX_STATUS_LABELS: Record<SandboxStatusMode, string> = {
	full: "Sandbox (fs + net)",
	filesystem: "Sandbox (fs)",
	disabled: "Sandbox (disabled)",
};

/**
 * Set the sandbox status bar entry.
 * Green for active modes (full, filesystem), red when disabled.
 */
export function setSandboxStatus(mode: SandboxStatusMode, ctx: ExtensionContext): void {
	if (!ctx.hasUI) return;
	const label = SANDBOX_STATUS_LABELS[mode];
	const color = mode === "disabled" ? "error" : "success";
	ctx.ui.setStatus(SANDBOX_STATUS_REGION, ctx.ui.theme.fg(color, label));
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
