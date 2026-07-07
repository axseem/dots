import { z } from "zod";

export default {
  description:
    "Search the web via local SearXNG. Aggregates 30+ engines: general web " +
    "(google, brave, duckduckgo, startpage, qwant, mojeek), academic " +
    "(arxiv, pubmed, openalex, semantic scholar, crossref, google scholar), " +
    "code/docs (github, gitlab, stackoverflow, mdn, arch/nixos wiki), " +
    "packages (npm, pypi, crates.io), and reference (wikipedia, wolframalpha). " +
    "Returns ranked results with titles, URLs, snippets. " +
    "Flags: -c <categories> (general,news,science,it,files), -e <engines> " +
    "(shortcuts: arx,gh,so,wp,npm,pyp,crs,etc), -t <d|w|m|y>, -n <limit>, -l <lang>. " +
    "Pass -c general for general queries, -c science for research, -c it for code/tech " +
    "to reduce noise from off-topic engines.",
  args: {
    query: z.string().describe("Search query"),
    limit: z.number().optional().describe("Max results (default 10)"),
  },
  async execute(args) {
    const cmd = ["sxng"];
    if (args.limit) cmd.push("-n", String(args.limit));
    cmd.push("--", args.query);
    const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();
    const exit = await proc.exited;
    if (exit !== 0) return `Error (exit ${exit}): ${stderr.trim()}`;
    return stdout.trim();
  },
} as const;
