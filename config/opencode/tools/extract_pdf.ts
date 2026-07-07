import { z } from "zod";
import { $ } from "bun";
import path from "path";
import { existsSync, statSync } from "fs";
import { tmpdir } from "os";

export default {
  description:
    "Extract well-structured text content from PDF files (local path or URL). " +
    "Use this tool when you need to read a PDF — the built-in `read` tool cannot extract PDF text. " +
    "Supports local files and https:// URLs. Works with extractable text PDFs (not scanned images).",
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
        "Page range to extract (e.g. '1-5', '3', '1-10', '1 - 5'). Omit for all pages.",
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
      tmpFile = path.join(tmpdir(), `extractpdf-${Date.now()}.pdf`);
      const proc = Bun.spawn(["curl", "-fsSL", "-o", tmpFile, args.source], {
        stdout: "pipe",
        stderr: "pipe",
      });
      const stderr = await new Response(proc.stderr).text();
      const exit = await proc.exited;
      if (exit !== 0) {
        const hint = stderr.includes("404")
          ? "URL not found (404)"
          : stderr.includes("Could not resolve")
            ? "DNS resolution failed"
            : stderr.includes("Connection refused")
              ? "Connection refused"
              : `curl exit ${exit}`;
        return `Error downloading PDF: ${hint}\n${stderr.trim()}`;
      }
      filePath = tmpFile;
    } else {
      filePath = path.isAbsolute(args.source)
        ? args.source
        : path.join(context.directory, args.source);
      if (!existsSync(filePath)) return `Error: file not found: ${filePath}`;
    }

    // Warn about large PDFs before extraction
    try {
      const sizeMb = statSync(filePath).size / (1024 * 1024);
      if (sizeMb > 50) {
        return `Error: PDF is ${sizeMb.toFixed(0)} MB — too large to extract as text. Use a different approach.`;
      }
    } catch {}

    try {
      return await extractText(filePath, args);
    } finally {
      if (tmpFile) {
        await $`rm -f ${tmpFile}`.quiet().nothrow();
      }
    }
  },
} as const;

async function extractText(
  filePath: string,
  args: { pages?: string; layout?: boolean },
) {
  // Check pdftotext availability early
  const which = await $`which pdftotext`.quiet().nothrow();
  if (which.exitCode !== 0) {
    return "Error: pdftotext not found. Install poppler-utils (e.g. `nix-shell -p poppler` or `apt install poppler-utils`).";
  }

  // Extract metadata
  const info = await $`pdfinfo -enc UTF-8 ${filePath}`
    .quiet()
    .text()
    .catch(() => "");
  const pageCount = info.match(/Pages:\s+(\d+)/)?.[1];
  const title = info.match(/Title:\s+(.+)/)?.[1]?.trim();

  // Build pdftotext command
  const preserveLayout = args.layout !== false;
  const cmd = ["pdftotext", "-enc", "UTF-8"];
  if (preserveLayout) cmd.push("-layout");

  if (args.pages) {
    const range = parsePageRange(args.pages);
    if (!range) {
      return `Error: invalid page range "${args.pages}". Expected format like "1-5", "3", or "1-10".`;
    }
    cmd.push("-f", String(range[0]), "-l", String(range[1]));
  }

  cmd.push(filePath, "-");

  // Extract text
  const proc = Bun.spawn(cmd, { stdout: "pipe", stderr: "pipe" });
  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exit = await proc.exited;

  if (exit !== 0) {
    return `Error: pdftotext failed (exit ${exit}): ${stderr.trim()}`;
  }

  const text = stdout.trim();
  if (!text) {
    return [
      `Pages: ${pageCount ?? "unknown"}`,
      `Title: ${title ?? "(none)"}`,
      "",
      "No text extracted. The PDF may be scanned/image-based. Consider OCR.",
    ].join("\n");
  }

  // Build output header
  const lines: string[] = [];
  if (title) lines.push(`Title: ${title}`);
  lines.push(
    `Pages: ${pageCount ?? "unknown"}` +
      (args.pages ? ` (requested: ${args.pages})` : ""),
  );
  lines.push("---");
  lines.push(text);

  return lines.join("\n");
}

function parsePageRange(range: string): [number, number] | null {
  // Allow spaces: "1 - 5", "1-5", "3"
  const m = range.trim().match(/^(\d+)\s*(?:-\s*(\d+))?$/);
  if (!m) return null;
  const start = parseInt(m[1], 10);
  const end = m[2] ? parseInt(m[2], 10) : start;
  if (start < 1 || end < start) return null;
  return [start, end];
}
