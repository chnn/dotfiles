/**
 * AGENTS.md Extension
 *
 * Before the agent edits or writes a file, this extension surfaces the
 * content of any AGENTS.md files that live in the target file's ancestor
 * directories — from the project root (ctx.cwd) down to the directory that
 * contains (or will contain) the file being changed.
 *
 * Behavior
 * --------
 *   - Triggers on the built-in `edit` and `write` tool calls.
 *   - For a target at `a/b/c/foo.ts`, it looks for AGENTS.md in:
 *         <cwd>/AGENTS.md
 *         <cwd>/a/AGENTS.md
 *         <cwd>/a/b/AGENTS.md
 *         <cwd>/a/b/c/AGENTS.md
 *   - The first time any of those files applies, the tool call is blocked
 *     and the file contents are returned as the tool's error result. The
 *     LLM reads the guidance in the next assistant step, then retries the
 *     edit (or adjusts its approach to comply).
 *   - Each AGENTS.md is only surfaced once per session (keyed by the
 *     resolved absolute path). Subsequent edits under the same directory
 *     are not interrupted.
 *   - Targets outside of cwd are ignored.
 *
 * Drop this file into `~/.pi/agent/extensions/` (or a project's
 * `.pi/extensions/`) and it will be auto-discovered on the next run. Use
 * `/reload` to pick up changes without restarting pi.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const AGENTS_FILE = "AGENTS.md";
const TRIGGER_TOOLS = new Set(["edit", "write"]);

/**
 * Resolve a tool-provided path to an absolute filesystem path, mirroring
 * the same leading-`@` stripping that pi's own built-in tools perform.
 */
function resolveTargetPath(raw: unknown, cwd: string): string | null {
  if (typeof raw !== "string" || raw.length === 0) return null;
  const cleaned = raw.startsWith("@") ? raw.slice(1) : raw;
  return path.resolve(cwd, cleaned);
}

/**
 * Return the absolute paths of every AGENTS.md file that lives between
 * `cwd` (inclusive) and the directory containing `targetFile` (inclusive),
 * in root-to-leaf order.
 *
 * Returns an empty list when `targetFile` is outside of `cwd`.
 */
function findApplicableAgentsFiles(targetFile: string, cwd: string): string[] {
  const rootAbs = path.resolve(cwd);
  const targetAbs = path.resolve(targetFile);

  const rel = path.relative(rootAbs, targetAbs);
  if (!rel || rel.startsWith("..") || path.isAbsolute(rel)) {
    // Target is at or above cwd, or on a different volume.
    return [];
  }

  // Walk down from rootAbs to the parent directory of the target, one
  // segment at a time, checking for AGENTS.md at every level.
  const parentDir = path.dirname(targetAbs);
  const relParent = path.relative(rootAbs, parentDir);
  const segments = relParent ? relParent.split(path.sep).filter(Boolean) : [];

  const dirs: string[] = [rootAbs];
  let current = rootAbs;
  for (const segment of segments) {
    current = path.join(current, segment);
    dirs.push(current);
  }

  const results: string[] = [];
  for (const dir of dirs) {
    const candidate = path.join(dir, AGENTS_FILE);
    try {
      const stat = fs.statSync(candidate);
      if (!stat.isFile()) continue;
      // Canonicalize through realpath so symlinked aliases don't
      // cause the same file to be surfaced twice.
      let resolved = candidate;
      try {
        resolved = fs.realpathSync(candidate);
      } catch {
        // realpath can fail on exotic filesystems; fall back to
        // the literal candidate path.
      }
      results.push(resolved);
    } catch {
      // Missing or unreadable at this level — skip.
    }
  }

  return results;
}

function readAgentsFile(absolutePath: string): string {
  try {
    return fs.readFileSync(absolutePath, "utf-8").trim();
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return `<could not read AGENTS.md: ${msg}>`;
  }
}

function buildBlockReason(
  toolName: string,
  targetRel: string,
  pending: Array<{ absPath: string; displayPath: string }>,
): string {
  const verb = toolName === "edit" ? "editing" : "writing";
  const sections = pending.map(({ absPath, displayPath }) => {
    const body = readAgentsFile(absPath);
    return `### ${displayPath}\n\n${body}`;
  });

  return [
    `Before ${verb} \`${targetRel}\`, review the AGENTS.md guidance below.`,
    `These files apply to the target path and had not yet been surfaced in this session.`,
    `After reading, retry the tool call — adjusting your change to follow the instructions.`,
    "",
    sections.join("\n\n"),
  ].join("\n");
}

export default function agentsMdExtension(pi: ExtensionAPI) {
  // Absolute (realpath-resolved) paths of AGENTS.md files that have
  // already been surfaced to the LLM during this session.
  const delivered = new Set<string>();

  pi.on("session_start", async () => {
    delivered.clear();
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!TRIGGER_TOOLS.has(event.toolName)) return undefined;

    const rawPath = (event.input as { path?: unknown } | undefined)?.path;
    const target = resolveTargetPath(rawPath, ctx.cwd);
    if (!target) return undefined;

    const agentsFiles = findApplicableAgentsFiles(target, ctx.cwd);
    if (agentsFiles.length === 0) return undefined;

    const pending = agentsFiles
      .filter((absPath) => !delivered.has(absPath))
      .map((absPath) => ({
        absPath,
        displayPath: path.relative(ctx.cwd, absPath) || absPath,
      }));

    if (pending.length === 0) return undefined;

    // Mark them delivered up-front so parallel/sibling tool calls in
    // the same assistant message don't re-block on the same files.
    for (const { absPath } of pending) delivered.add(absPath);

    const targetRel = path.relative(ctx.cwd, target) || target;
    const reason = buildBlockReason(event.toolName, targetRel, pending);

    if (ctx.hasUI) {
      const names = pending.map((p) => p.displayPath).join(", ");
      ctx.ui.notify(`Loaded ${AGENTS_FILE}: ${names}`, "info");
    }

    return { block: true, reason };
  });
}
