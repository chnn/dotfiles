/**
 * /files extension
 *
 * Shows a fuzzy selector of files that have been modified (via edit/write
 * tool calls) during the current Pi session branch. Selecting a file splits
 * the current Ghostty pane downward and opens the file in $EDITOR via
 * Ghostty's AppleScript API.
 *
 * Requirements:
 * - macOS with Ghostty >= 1.3 (AppleScript support)
 * - osascript on PATH (standard on macOS)
 * - EDITOR (or VISUAL) set in your shell env; falls back to `vi`
 */

import { execFile } from "node:child_process";
import { platform } from "node:os";
import { relative } from "node:path";
import { promisify } from "node:util";

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import {
  Container,
  fuzzyFilter,
  Input,
  type SelectItem,
  SelectList,
  Text,
} from "@mariozechner/pi-tui";

const execFileAsync = promisify(execFile);

// ---------------------------------------------------------------------------
// Session scanning
// ---------------------------------------------------------------------------

interface ToolCallRef {
  name: string;
  path?: string;
}

/**
 * Walk the current branch and return absolute paths of files that were
 * successfully modified by edit/write tool calls, ordered most-recent first.
 */
function collectModifiedFiles(ctx: ExtensionContext): string[] {
  const branch = ctx.sessionManager.getBranch();

  // Map toolCallId -> { toolName, path } as we walk assistant messages.
  const pendingCalls = new Map<string, ToolCallRef>();

  // absolutePath -> order index (higher = more recent)
  const seen = new Map<string, number>();

  let order = 0;
  for (const entry of branch) {
    if (entry.type !== "message") continue;
    const msg = (entry as { message?: unknown }).message as
      | {
          role?: string;
          content?: unknown;
          toolCallId?: string;
          toolName?: string;
          isError?: boolean;
        }
      | undefined;
    if (!msg) continue;

    if (msg.role === "assistant" && Array.isArray(msg.content)) {
      for (const block of msg.content as Array<{
        type?: string;
        id?: string;
        name?: string;
        arguments?: { path?: unknown };
      }>) {
        if (block?.type !== "toolCall") continue;
        if (typeof block.id !== "string") continue;
        if (block.name !== "edit" && block.name !== "write") continue;
        const rawPath = block.arguments?.path;
        pendingCalls.set(block.id, {
          name: block.name,
          path: typeof rawPath === "string" ? rawPath : undefined,
        });
      }
      continue;
    }

    if (msg.role === "toolResult") {
      const callId = msg.toolCallId;
      if (typeof callId !== "string") continue;
      const call = pendingCalls.get(callId);
      if (!call || !call.path) continue;
      // Only count successful modifications.
      if (msg.isError) continue;

      // Normalize to absolute path for dedup.
      const abs = resolveAbsolute(call.path, ctx.cwd);
      seen.set(abs, ++order);
    }
  }

  return Array.from(seen.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([p]) => p);
}

function resolveAbsolute(p: string, cwd: string): string {
  // pi's own tools strip a leading '@'; mirror that defensively.
  const cleaned = p.startsWith("@") ? p.slice(1) : p;
  if (cleaned.startsWith("/")) return cleaned;
  return `${cwd.replace(/\/$/, "")}/${cleaned}`;
}

// ---------------------------------------------------------------------------
// Ghostty AppleScript
// ---------------------------------------------------------------------------

function escapeAppleScriptString(s: string): string {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function shellQuote(s: string): string {
  // POSIX single-quote: close quote, escape literal ', reopen quote.
  return `'${s.replace(/'/g, "'\\''")}'`;
}

function buildOpenScript(filePath: string): string {
  // Use the shell to resolve $EDITOR at runtime so the user's shell config
  // wins (aliases, functions, shell-set EDITOR). Falls back to `vi`.
  const command = `\${EDITOR:-\${VISUAL:-vi}} ${shellQuote(filePath)}`;
  const escaped = escapeAppleScriptString(command);
  return `
tell application "Ghostty"
    activate
    set currentTerm to focused terminal of selected tab of front window
    set newTerm to split currentTerm direction down
    input text "${escaped}" to newTerm
    send key "enter" to newTerm
    focus newTerm
end tell
`.trim();
}

async function openInGhostty(filePath: string, signal?: AbortSignal): Promise<void> {
  const script = buildOpenScript(filePath);
  await execFileAsync("/usr/bin/osascript", ["-e", script], { signal });
}

// ---------------------------------------------------------------------------
// Fuzzy selector UI (SelectList + Input)
// ---------------------------------------------------------------------------

async function pickFile(ctx: ExtensionContext, files: string[]): Promise<string | null> {
  const items: SelectItem[] = files.map((abs) => {
    const rel = relative(ctx.cwd, abs);
    // Prefer relative label when inside cwd, otherwise show absolute.
    const inside = rel && !rel.startsWith("..") && !rel.startsWith("/");
    return {
      value: abs,
      label: inside ? rel : abs,
    };
  });

  return ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const container = new Container();
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

    container.addChild(
      new Text(
        theme.fg("accent", theme.bold("Files modified this session")) +
          "  " +
          theme.fg("dim", `(${items.length})`),
        1,
        0,
      ),
    );

    const searchInput = new Input();
    searchInput.focused = true;
    container.addChild(searchInput);

    const selectList = new SelectList(
      items,
      Math.min(Math.max(items.length, 1), 12),
      {
        selectedPrefix: (t) => theme.fg("accent", t),
        selectedText: (t) => theme.fg("accent", t),
        description: (t) => theme.fg("muted", t),
        scrollInfo: (t) => theme.fg("dim", t),
        noMatch: (t) => theme.fg("warning", t),
      },
      { minPrimaryColumnWidth: 10, maxPrimaryColumnWidth: 200 },
    );
    selectList.onSelect = (item) => done(item.value);
    selectList.onCancel = () => done(null);
    container.addChild(selectList);

    container.addChild(
      new Text(theme.fg("dim", "type to filter • ↑↓ navigate • enter select • esc cancel"), 1, 0),
    );
    container.addChild(new DynamicBorder((s: string) => theme.fg("accent", s)));

    // Monkey-patch SelectList.setFilter to use fuzzyFilter for ranked matching.
    // SelectList's built-in setFilter only does prefix matching on `value`.
    const applyFilter = (query: string) => {
      if (!query) {
        // Reset to original order.
        (selectList as unknown as { filteredItems: SelectItem[] }).filteredItems = items;
      } else {
        const filtered = fuzzyFilter(items, query, (item) => item.label ?? item.value);
        (selectList as unknown as { filteredItems: SelectItem[] }).filteredItems = filtered;
      }
      selectList.setSelectedIndex(0);
    };

    return {
      render: (w) => container.render(w),
      invalidate: () => container.invalidate(),
      handleInput: (data: string) => {
        // Let the select list handle navigation/confirm/cancel first.
        if (
          data === "\r" ||
          data === "\n" ||
          data === "\x1b" ||
          data === "\x1b[A" ||
          data === "\x1b[B" ||
          data === "\x03" // Ctrl+C
        ) {
          selectList.handleInput(data);
          tui.requestRender();
          return;
        }
        // Route everything else (printable chars + backspace + word-edits)
        // into the search input.
        const before = searchInput.getValue();
        searchInput.handleInput(data);
        const after = searchInput.getValue();
        if (before !== after) {
          applyFilter(after);
        }
        tui.requestRender();
      },
    };
  });
}

// ---------------------------------------------------------------------------
// Command registration
// ---------------------------------------------------------------------------

export default function filesExtension(pi: ExtensionAPI) {
  pi.registerCommand("files", {
    description: "Fuzzy-pick a file modified this session; open it in a new Ghostty split",
    handler: async (_args, ctx) => {
      if (platform() !== "darwin") {
        ctx.ui.notify("/files requires macOS + Ghostty", "error");
        return;
      }

      const files = collectModifiedFiles(ctx);
      if (files.length === 0) {
        ctx.ui.notify("No files have been modified in this session yet", "info");
        return;
      }

      const selected = await pickFile(ctx, files);
      if (!selected) return;

      try {
        await openInGhostty(selected);
        ctx.ui.notify(`Opened ${relative(ctx.cwd, selected) || selected}`, "success");
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        ctx.ui.notify(`Failed to open in Ghostty: ${msg}`, "error");
      }
    },
  });
}
