import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { Config } from "./config.js";
import { searchPrimo } from "./primoClient.js";

export function createMcpServer(config: Config): McpServer {
  const server = new McpServer({
    name: "primo-search",
    version: "1.0.0",
  });

  server.tool(
    "primo_search",
    "Search a library catalog using the Ex Libris Primo Search API. " +
      "Provide a simple keyword query OR an advanced query in Primo's q format. " +
      "Returns bibliographic records including titles, authors, subjects, and availability.",
    {
      query: z
        .string()
        .optional()
        .describe(
          "Simple keyword search. The server wraps this as any,contains,<query>.",
        ),
      advancedQuery: z
        .string()
        .optional()
        .describe(
          "Raw Primo q parameter format for field-specific searches. " +
            "Format: field,precision,value[,operator;field,precision,value...]. " +
            "Fields: any, title, creator, sub, usertag. " +
            "Precisions: exact, begins_with, contains. " +
            "Operators: AND, OR, NOT. " +
            "Example: title,contains,machine learning,AND;sub,contains,neural networks",
        ),
      limit: z
        .number()
        .int()
        .min(1)
        .max(50)
        .optional()
        .describe("Maximum number of results (1-50, default 10)."),
      offset: z
        .number()
        .int()
        .min(0)
        .max(5000)
        .optional()
        .describe("Offset for pagination (0-5000, default 0)."),
      sort: z
        .enum(["rank", "title", "author", "date", "date_d", "date_a"])
        .optional()
        .describe(
          "Sort order: rank (relevance), title, author, date, date_d (newest), date_a (oldest).",
        ),
      qInclude: z
        .string()
        .optional()
        .describe(
          "Include facet filter. Format: facet_category,exact,facet_name. " +
            "Categories: facet_rtype, facet_topic, facet_creator, facet_tlevel, " +
            "facet_domain, facet_library, facet_lang, facet_lcc, facet_searchcreationdate. " +
            "Multiple facets delimited by |,|",
        ),
      qExclude: z
        .string()
        .optional()
        .describe(
          "Exclude facet filter. Same format as qInclude.",
        ),
      lang: z
        .string()
        .optional()
        .describe("Language code (e.g., 'en' for Primo VE, 'en_US' for Primo)."),
    },
    async (params) => {
      if (!params.query && !params.advancedQuery) {
        return {
          content: [
            {
              type: "text" as const,
              text: "Error: Either 'query' or 'advancedQuery' must be provided.",
            },
          ],
          isError: true,
        };
      }

      const q = params.advancedQuery ?? `any,contains,${params.query}`;

      const result = await searchPrimo(config, {
        q,
        limit: params.limit,
        offset: params.offset,
        sort: params.sort,
        qInclude: params.qInclude,
        qExclude: params.qExclude,
        lang: params.lang,
      });

      if (result.status !== 200) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Primo API error (HTTP ${result.status}): ${JSON.stringify(result.data)}`,
            },
          ],
          isError: true,
        };
      }

      const responseText = JSON.stringify(result.data, null, 2);
      const meta = result.apiRemaining
        ? `\n\n---\nAPI calls remaining: ${result.apiRemaining}`
        : "";

      return {
        content: [
          {
            type: "text" as const,
            text: responseText + meta,
          },
        ],
      };
    },
  );

  return server;
}
