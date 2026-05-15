import { z } from "zod";

export default {
  description:
    "Search the web. Returns ranked results with titles, URLs, and content snippets. " +
    "Works great in combination with webfetch tool.",
  args: {
    query: z.string().describe("Search query"),
    limit: z.number().optional().describe("Max results (default 10)"),
    time: z
      .enum(["d", "w", "m", "y"])
      .optional()
      .describe("Recency filter: d=day, w=week, m=month, y=year"),
    engines: z
      .string()
      .optional()
      .describe("Specific search engines, comma-separated"),
  },
  async execute(args) {
    const cmd = ["websearch"];
    if (args.limit) cmd.push("-n", String(args.limit));
    if (args.time) cmd.push("-t", args.time);
    if (args.engines) cmd.push("-e", args.engines);
    cmd.push("--", args.query);
    const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();
    const exit = await proc.exited;
    if (exit !== 0) return `Error (exit ${exit}): ${stderr.trim()}`;
    return stdout.trim();
  },
} as const;
