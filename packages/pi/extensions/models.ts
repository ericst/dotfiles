/**
 * Models Extension
 *
 * Provides quick model cycling via Alt+M for a curated list of models.
 * Model patterns ending in -latest are automatically resolved to the
 * latest available version from the provider.
 *
 * Usage: Alt+M cycles through configured models
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { Model } from "@mariozechner/pi-coding-agent";

/** Model patterns to cycle through. */
const MODEL_PATTERNS = [
	"anthropic/claude-sonnet-latest",
	"minimax/MiniMax-M-latest",
	"mistral/mistral-small-latest",
	"mistral/devstral-medium-latest",
	"local/qwen35-35b-a3b",
	"zai/glm-5",
];

export default function modelsExtension(pi: ExtensionAPI) {
	let resolvedModels: Model[] = [];
	let currentIndex = 0;

	/**
	 * Calculate a score for a version string based on digit sequence.
	 * Higher score = newer version.
	 */
	function calculateVersionScore(versionStr: string): number {
		let score = 0;
		let weight = 100000;

		for (const char of versionStr) {
			if (char >= "0" && char <= "9") {
				const digit = parseInt(char, 10);
				score += weight * digit;
				if (weight >= 10) {
					weight = Math.floor(weight / 10);
				} else {
					weight = weight / 10;
				}
			} else {
				// Non-digit resets weight to allow comparison of parallel sequences
				weight = 100000;
			}
		}

		return score;
	}

	/**
	 * Extract version portion from a model ID after the given prefix.
	 * E.g., "MiniMax-M2.7-highspeed" with prefix "MiniMax-M" gives "2.7-highspeed"
	 */
	function extractVersion(modelId: string, prefix: string): string {
		if (modelId.startsWith(prefix)) {
			return modelId.slice(prefix.length);
		}
		return modelId;
	}

	/**
	 * Check if a model ID contains a date pattern (YYYYMMDD or similar).
	 */
	function hasDatePattern(modelId: string): boolean {
		// Check for 8-digit date pattern like 20250101
		if (/\d{8}/.test(modelId)) return true;
		// Check for 6-digit date pattern like 250101
		if (/\d{6}/.test(modelId)) return true;
		return false;
	}

	/**
	 * Resolve a model pattern to an actual model.
	 * For patterns ending in -latest:
	 *   1. If exact model exists, return it
	 *   2. Otherwise, find all models starting with the prefix (minus -latest)
	 *   3. Filter out models with date patterns
	 *   4. Score by version number, prefer shortest name on tie
	 */
	function resolvePattern(pattern: string, available: Model[]): Model | undefined {
		const [provider, ...idParts] = pattern.split("/");
		const modelId = idParts.join("/");
		const providerModels = available.filter((m) => m.provider === provider);

		if (providerModels.length === 0) return undefined;

		// Check for exact match first
		const exactMatch = providerModels.find((m) => m.id === modelId);
		if (exactMatch) return exactMatch;

		// Handle -latest suffix
		if (modelId.endsWith("-latest")) {
			const prefix = modelId.slice(0, -7); // Remove "-latest"
			const candidates = providerModels.filter(
				(m) => m.id.startsWith(prefix) && m.id !== modelId && !hasDatePattern(m.id),
			);

			if (candidates.length === 0) return undefined;

			// Score each candidate and sort by score desc, then name length asc
			const scored = candidates.map((m) => ({
				model: m,
				score: calculateVersionScore(extractVersion(m.id, prefix)),
				nameLength: m.id.length,
			}));

			scored.sort((a, b) => {
				if (b.score !== a.score) return b.score - a.score;
				return a.nameLength - b.nameLength;
			});

			return scored[0].model;
		}

		// For non-latest patterns, try exact match (already checked above)
		return providerModels.find((m) => m.id === modelId);
	}

	/**
	 * Cycle to the next model in the list.
	 */
	async function cycleModel(ctx: ExtensionContext): Promise<void> {
		if (resolvedModels.length === 0) {
			return;
		}

		currentIndex = (currentIndex + 1) % resolvedModels.length;
		const model = resolvedModels[currentIndex];

		const success = await pi.setModel(model);
		if (!success) {
			ctx.ui.notify(`No API key for ${model.provider}/${model.id}`, "error");
		} else {
			ctx.ui.notify(`Model: ${model.id}`);
		}
	}

	// Register Alt+M shortcut
	pi.registerShortcut("alt+m", {
		description: "Cycle through configured models",
		handler: async (ctx) => {
			await cycleModel(ctx);
		},
	});

	// Initialize on session start
	pi.on("session_start", async (_event, ctx) => {
		const available = await ctx.modelRegistry.getAvailable();

		// Resolve all model patterns
		resolvedModels = [];
		for (const pattern of MODEL_PATTERNS) {
			const model = resolvePattern(pattern, available);
			if (model) {
				resolvedModels.push(model);
			}
		}

		// Find current model in the resolved list
		const currentModel = ctx.model;
		if (currentModel) {
			const idx = resolvedModels.findIndex(
				(m) => m.provider === currentModel.provider && m.id === currentModel.id,
			);
			if (idx !== -1) {
				currentIndex = idx;
			}
		}
	});
}
