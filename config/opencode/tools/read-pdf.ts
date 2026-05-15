import { z } from "zod";
import path from "path";
import { existsSync } from "fs";
import { tmpdir } from "os";

export default {
  description:
    "Extract text content from PDF files (local path or URL). Returns page-delimited text with metadata.",
  args: {
    source: z
      .string()
      .describe(
        "PDF to read: a local file path (absolute or relative) or a URL (https://...)",
      ),
    pages: z
      .string()
      .optional()
      .describe(
        "Page range to extract (e.g. '1-5', '3', '1-10'). Omit for all pages.",
      ),
    layout: z
      .boolean()
      .optional()
      .describe(
        "Preserve visual layout of text (default: true). Disable for continuous text flow.",
      ),
  },
  async execute(args, context) {
    const isUrl = /^https?:\/\//i.test(args.source);
    let filePath: string;
    let tmpFile: string | null = null;

    if (isUrl) {
      tmpFile = path.join(tmpdir(), `readpdf-${Date.now()}.pdf`);
      const proc = Bun.spawn(["curl", "-fsSL", "-o", tmpFile, args.source], {
        stdout: "pipe",
        stderr: "pipe",
      });
      const stderr = await new Response(proc.stderr).text();
      const exit = await proc.exited;
      if (exit !== 0)
        return `Error downloading PDF (exit ${exit}): ${stderr.trim()}`;
      filePath = tmpFile;
    } else {
      filePath = path.isAbsolute(args.source)
        ? args.source
        : path.join(context.directory, args.source);
      if (!existsSync(filePath))
        return `Error: file not found: ${filePath}`;
    }

    try {
      return await extractPdf(filePath, args);
    } finally {
      if (tmpFile) {
        try { await Bun.write(tmpFile, ""); } catch {}
        try { Bun.spawn(["rm", "-f", tmpFile]); } catch {}
      }
    }
  },
} as const;

async function extractPdf(
  filePath: string,
  args: { pages?: string; layout?: boolean },
) {
  const info = await Bun.$`pdfinfo -enc UTF-8 ${filePath}`
    .quiet()
    .text()
    .catch(() => "");
  const pageCount = info.match(/Pages:\s+(\d+)/)?.[1];
  const title = info.match(/Title:\s+(.+)/)?.[1]?.trim();

  const preserveLayout = args.layout !== false;
  const cmd = ["pdftotext", "-enc", "UTF-8"];
  if (preserveLayout) cmd.push("-layout");

  if (args.pages) {
    const parsed = parsePageRange(args.pages);
    if (parsed) {
      const [start, end] = parsed;
      cmd.push("-f", String(start), "-l", String(end));
    }
  }

  cmd.push(filePath, "-");

  const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exit = await proc.exited;

  if (exit !== 0) return `Error (exit ${exit}): ${stderr.trim()}`;

  const text = stdout.trim();
  if (!text) {
    return [
      title && `Title: ${title}`,
      `Pages: ${pageCount ?? "unknown"}`,
      "",
      "No text extracted. The PDF may be scanned/image-based. Consider OCR.",
    ]
      .filter(Boolean)
      .join("\n");
  }

  const header = [
    title && `Title: ${title}`,
    `Pages: ${pageCount ?? "unknown"}` +
      (args.pages ? ` (showing ${args.pages})` : ""),
    "---",
  ]
    .filter((l) => l !== false)
    .join("\n");

  return header + "\n" + text;
}

function parsePageRange(range: string): [number, number] | null {
  const m = range.match(/^(\d+)(?:\s*-\s*(\d+))?$/);
  if (!m) return null;
  const start = parseInt(m[1]);
  const end = m[2] ? parseInt(m[2]) : start;
  if (start < 1 || end < start) return null;
  return [start, end];
}
