/**
 * WebTools Extension - WebSearch and WebFetch tools using SearXNG and Crawl4AI
 *
 * Provides:
 * - WebSearch: Search the web via self-hosted SearXNG instance
 * - WebFetch: Fetch web pages via Crawl4AI and return markdown
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { keyHint, keyText } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { Text } from "@mariozechner/pi-tui";
import { execFileSync } from "node:child_process";

// Interfaces for tool details
interface WebSearchDetails {
  query: string;
  resultCount: number;
}

interface WebFetchDetails {
  url: string;
  originalSizeBytes: number;
}

// SearXNG instance URL
const SEARXNG_BASE = "https://searx.mars.ericst.ch";
// Crawl4AI instance URL
const CRAWL4AI_BASE = "https://crawl4ai.mars.ericst.ch";

// Helper to fetch using curl (handles self-signed certs easily)
async function curlFetch(
  url: string,
  headers: Record<string, string> = {},
  body?: string,
): Promise<{ body: string; status: number }> {
  const args = ["-s", "-k", "-w", "\n%{http_code}"];
  for (const [k, v] of Object.entries(headers)) {
    args.push("-H", `${k}: ${v}`);
  }
  if (body) {
    args.push("-d", body);
  }
  args.push(url);
  const output = execFileSync("curl", args, { encoding: "utf8" });

  // Extract status code from last line
  const lines = output.trim().split("\n");
  const status = parseInt(lines.pop() || "000", 10);
  const responseBody = lines.join("\n");

  return { body: responseBody, status };
}

export default function webtoolsExtension(pi: ExtensionAPI) {
  // Register WebSearch tool
  pi.registerTool({
    name: "websearch",
    label: "WebSearch",
    description: "Search the web using a self-hosted SearXNG instance. Returns a list of search results with titles, URLs, and descriptions. Use this when you need to find information on the web.",
    promptSnippet: "Search the web via SearXNG to find information, links, and resources",
    parameters: Type.Object({
      query: Type.String({ description: "The search query" }),
    }),

    async execute(_toolCallId, params, signal) {
      const { query } = params as { query: string };

      try {
        // Build the SearXNG search URL
        const searchUrl = `${SEARXNG_BASE}/search?q=${encodeURIComponent(query)}&format=json`;

        const { body, status } = await curlFetch(searchUrl);

        if (status !== 200) {
          throw new Error(`SearXNG returned HTTP ${status}`);
        }

        const data = JSON.parse(body) as {
          results?: Array<{
            title?: string;
            url?: string;
            content?: string;
            description?: string;
          }>;
          answers?: string[];
          infoboxes?: Array<{
            content?: string;
            entities?: Array<{
              content?: string;
            }>;
          }>;
        };

        const results = data.results || [];
        const hasAnswers = data.answers && data.answers.length > 0;
        const hasInfoboxes = data.infoboxes && data.infoboxes.length > 0;

        if (results.length === 0 && !hasAnswers && !hasInfoboxes) {
          throw new Error("No search results found");
        }

        // Format results
        let output = "";

        for (const result of results) {
          const title = result.title || "Untitled";
          const url = result.url || "";
          const description = result.description || result.content || "";

          output += `## ${title}\n`;
          output += `URL: ${url}\n`;
          if (description) {
            output += `Description: ${description}\n`;
          }
          output += "\n---\n\n";
        }

        // Add infoboxes/answers if available
        if (hasAnswers) {
          output += "\n## Answers\n\n";
          for (const answer of data.answers!) {
            output += `${answer}\n\n`;
          }
        }

        if (hasInfoboxes) {
          output += "\n## Infoboxes\n\n";
          for (const infobox of data.infoboxes!) {
            if (infobox.content) {
              output += `${infobox.content}\n\n`;
            }
            if (infobox.entities) {
              for (const entity of infobox.entities) {
                if (entity.content) {
                  output += `- ${entity.content}\n`;
                }
              }
            }
          }
        }

        return {
          content: [{ type: "text", text: output.trim() }],
          details: {
            query,
            resultCount: results.length,
          },
        };
      } catch (error) {
        const message = error instanceof Error ? error.message : "Unknown error";
        throw new Error(`WebSearch failed: ${message}`);
      }
    },

    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("websearch ")) +
          theme.fg("accent", `"${args.query}"`),
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as WebSearchDetails;

      if (details.resultCount === 0) {
        return new Text(theme.fg("dim", "No results found"), 0, 0);
      }

      // Collapsed view - summary only
      if (!expanded) {
        let text = theme.fg("success", `${details.resultCount} results`);
        text += theme.fg("dim", ` for "${details.query}"`);
        text += theme.fg("muted", ` (${keyText("app.tools.expand")} to expand)`);
        return new Text(text, 0, 0);
      }

      // Expanded view - show ALL content
      let text = theme.fg("success", `${details.resultCount} results`);
      text += theme.fg("dim", ` for "${details.query}"`);

      const content = result.content[0];
      if (content?.type === "text") {
        const lines = content.text.split("\n");
        // Show ALL lines
        for (const line of lines) {
          text += `\n${theme.fg("dim", line)}`;
        }
        // Add hint to collapse
        text += `\n${theme.fg("muted", `(${keyHint("app.tools.expand", "to collapse")})`)}`;
      }

      return new Text(text, 0, 0);
    },
  });

  // Register WebFetch tool
  pi.registerTool({
    name: "webfetch",
    label: "WebFetch",
    description: "Fetch a web page and convert it to markdown-like text. Use this after WebSearch to retrieve the content of a specific URL.",
    promptSnippet: "Fetch and parse a web page URL to retrieve its content",
    parameters: Type.Object({
      url: Type.String({ description: "The URL to fetch" }),
    }),

    async execute(_toolCallId, params, signal) {
      const { url } = params as { url: string };

      // Basic URL validation
      try {
        new URL(url);
      } catch {
        throw new Error("Invalid URL provided");
      }

      try {
        // Call Crawl4AI /md endpoint
        const { body, status } = await curlFetch(
          `${CRAWL4AI_BASE}/md`,
          { "Content-Type": "application/json" },
          JSON.stringify({ url }),
        );

        if (status !== 200) {
          throw new Error(`Crawl4AI returned HTTP ${status}`);
        }

        const data = JSON.parse(body) as {
          success: boolean;
          markdown: string;
          url?: string;
        };

        if (!data.success) {
          throw new Error("Crawl4AI failed to process the page");
        }

        const markdown = data.markdown || "";
        const encoder = new TextEncoder();
        const originalSizeBytes = encoder.encode(markdown).length;

        return {
          content: [{ type: "text", text: markdown }],
          details: {
            url,
            originalSizeBytes,
          },
        };
      } catch (error) {
        const message = error instanceof Error ? error.message : "Unknown error";
        throw new Error(`WebFetch failed: ${message}`);
      }
    },

    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("webfetch ")) +
          theme.fg("accent", args.url),
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as WebFetchDetails;

      // Format size
      const sizeKB = Math.round(details.originalSizeBytes / 1024);
      const sizeStr = sizeKB >= 1024
        ? `${(sizeKB / 1024).toFixed(1)}MB`
        : `${sizeKB}KB`;

      // Collapsed view - summary only
      if (!expanded) {
        let text = theme.fg("success", "Fetched page");
        text += theme.fg("dim", ` (${sizeStr})`);
        text += theme.fg("muted", ` (${keyText("app.tools.expand")} to expand)`);
        return new Text(text, 0, 0);
      }

      // Expanded view - show ALL content
      let text = theme.fg("success", "Fetched page");
      text += theme.fg("dim", ` (${sizeStr})`);

      const content = result.content[0];
      if (content?.type === "text") {
        const lines = content.text.split("\n");
        // Show ALL lines
        for (const line of lines) {
          text += `\n${theme.fg("dim", line)}`;
        }
        // Add hint to collapse
        text += `\n${theme.fg("muted", `(${keyHint("app.tools.expand", "to collapse")})`)}`;
      }

      return new Text(text, 0, 0);
    },
  });
}
