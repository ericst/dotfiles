/**
 * WebTools Extension - WebSearch and WebFetch tools using SearXNG
 *
 * Provides:
 * - WebSearch: Search the web via self-hosted SearXNG instance
 * - WebFetch: Fetch web pages and convert to markdown-like text
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { Text } from "@mariozechner/pi-tui";
import { execFileSync } from "node:child_process";
import TurndownService from "turndown";

// SearXNG instance URL
const SEARXNG_BASE = "https://searx.mars.ericst.ch";

// Create Turndown instance with sensible defaults
const turndownService = new TurndownService({
  headingStyle: "atx",
  codeBlockStyle: "fenced",
  bulletListMarker: "-",
  emDelimiter: "*",
  strongDelimiter: "**",
});

// Add custom rule to remove scripts and styles
turndownService.addRule("removeScripts", {
  filter: ["script", "style", "noscript", "iframe", "svg", "math"],
  replacement: () => "",
});

// Add custom rule to clean up empty elements
turndownService.addRule("removeEmpty", {
  filter: (node) => {
    return node.nodeName === "DIV" && !node.textContent?.trim();
  },
  replacement: () => "",
});

// Helper to fetch using curl (handles self-signed certs easily)
async function curlFetch(url: string, headers: Record<string, string> = {}): Promise<{ body: string; status: number }> {
  const args = ["-s", "-k", "-w", "\n%{http_code}"];
  for (const [k, v] of Object.entries(headers)) {
    args.push("-H", `${k}: ${v}`);
  }
  args.push(url);
  const output = execFileSync("curl", args, { encoding: "utf8" });
  
  // Extract status code from last line
  const lines = output.trim().split("\n");
  const status = parseInt(lines.pop() || "000", 10);
  const body = lines.join("\n");
  
  return { body, status };
}

// Convert HTML to markdown using Turndown
function htmlToMarkdown(html: string): string {
  // Pre-process: remove scripts, styles, and other unwanted elements
  let cleaned = html
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "")
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, "")
    .replace(/<noscript\b[^<]*(?:(?!<\/noscript>)<[^<]*)*<\/noscript>/gi, "")
    .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, "")
    .replace(/<!--[\s\S]*?-->/g, ""); // Remove HTML comments
  
  // Convert to markdown
  let markdown = turndownService.turndown(cleaned);
  
  // Clean up excessive whitespace
  markdown = markdown
    .replace(/\n{3,}/g, "\n\n")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n[ \t]+/g, "\n")
    .trim();
  
  return markdown;
}

// Truncate text to a maximum size
function truncateText(text: string, maxBytes: number = 40000): { text: string; truncated: boolean; originalSize: number } {
  const encoder = new TextEncoder();
  const originalSize = encoder.encode(text).length;

  if (originalSize <= maxBytes) {
    return { text, truncated: false, originalSize };
  }

  // Truncate and add indicator
  return {
    text: text.slice(0, maxBytes) + "\n\n... [Content truncated - original was " + Math.round(originalSize / 1024) + "KB]",
    truncated: true,
    originalSize,
  };
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
        const { body, status } = await curlFetch(url, {
          "Accept": "text/html,application/xhtml+xml",
          "User-Agent": "Mozilla/5.0 (compatible; pi-coding-agent/1.0)",
        });

        if (status !== 200) {
          throw new Error(`HTTP ${status}`);
        }

        if (!body || body.trim().length === 0) {
          throw new Error("Empty response");
        }

        // Determine content type from response (curl doesn't give us headers easily)
        // Assume HTML if no content-type detection
        const contentType = "text/html";

        if (!contentType.includes("text/html")) {
          throw new Error(`Cannot fetch non-HTML content: ${contentType}`);
        }

        const markdown = htmlToMarkdown(body);
        const { text: truncatedMarkdown, truncated, originalSize } = truncateText(markdown);

        return {
          content: [{ type: "text", text: truncatedMarkdown }],
          details: {
            url,
            truncated,
            originalSizeBytes: originalSize,
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
  });
}
