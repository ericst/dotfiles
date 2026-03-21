/**
 * Exit Command
 *
 * This register the exit command. My muscle memory goes there autmatically...
 *
 */

import type { ExtensionAPI, SlashCommandInfo } from "@mariozechner/pi-coding-agent";

export default function commandsExtension(pi: ExtensionAPI) {
    // Register a /exit command that cleanly exits pi
	pi.registerCommand("exit", {
		description: "Exit pi cleanly",
		handler: async (_args, ctx) => {
			ctx.shutdown();
		},
    });
}


