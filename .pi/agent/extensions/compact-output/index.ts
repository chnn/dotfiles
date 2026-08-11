import { execFile } from "node:child_process";
import { parseStreamingJson } from "@earendil-works/pi-ai";
import { highlightCode, renderDiff } from "@earendil-works/pi-coding-agent";
import type {
  AgentToolResult,
  CodemodeToolDetails,
  ExtensionAPI,
  Theme,
  ToolRenderers,
} from "@earendil-works/pi-coding-agent";
import {
  type Component,
  type TuiMouseEvent,
  stripTerminalSequences,
  truncateToWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

import { installAssistantPanels } from "./assistant-panels.js";

const COLLAPSED = "";
const EXPANDED = "";
const EMPTY: Component = { render: () => [], invalidate() {} };
type HostContext = Parameters<NonNullable<ToolRenderers["renderCall"]>>[2];
type Result = AgentToolResult<unknown>;
type FormatCode = (code: string, cwd: string) => Promise<string>;
type NestedCall = CodemodeToolDetails["calls"][number];

interface RendererState {
  expanded?: boolean;
  hostExpanded?: boolean;
  /** Per-section overrides; unset sections follow `sectionsExpanded`. */
  sections?: Record<string, boolean>;
  sectionsExpanded?: boolean;
  result?: Result;
  format?: { code: string; value?: string };
}

type RenderContext = Omit<HostContext, "state"> & { state: RendererState };

/** Format an async function body, including scripts with top-level return/await. */
export function formatCode(code: string, cwd: string): Promise<string> {
  return new Promise((resolve) => {
    const child = execFile(
      "oxfmt",
      ["--stdin-filepath", "codemode.js"],
      { cwd, timeout: 3000, maxBuffer: 2 * 1024 * 1024, encoding: "utf8" },
      (error, stdout) => {
        if (error) return resolve(code); // Missing formatter, invalid code, or timeout.
        const body = stdout.match(
          /^async function __pi_codemode_render__\(\) \{\r?\n([\s\S]*)\r?\n\}\s*$/,
        )?.[1];
        if (body === undefined) return resolve(code);
        const indent = body.match(/^[ \t]+(?=\S)/m)?.[0] ?? "";
        resolve(
          body
            .split("\n")
            .map((line) => (line.startsWith(indent) ? line.slice(indent.length) : line))
            .join("\n"),
        );
      },
    );
    // A missing executable can close stdin before the write completes.
    child.stdin?.on("error", () => {});
    child.stdin?.end(`async function __pi_codemode_render__() {\n${code}\n}\n`);
  });
}

function clean(value: unknown): string {
  return stripTerminalSequences(typeof value === "string" ? value : "")
    .replace(/\r\n?/g, "\n")
    .replace(/[\u0000-\u0008\u000b-\u001f\u007f]/g, "")
    .replace(/\t/g, "  ");
}

function oneLine(value: unknown): string {
  return clean(value).replace(/\s+/g, " ").trim();
}

function json(value: unknown, pretty = false): string {
  try {
    return JSON.stringify(value, null, pretty ? 2 : undefined) ?? "";
  } catch {
    return "[unserializable arguments]";
  }
}

function asArgs(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" ? (value as Record<string, unknown>) : {};
}

function preview(tool: string, args: Record<string, unknown>): string {
  switch (tool) {
    case "read":
    case "write":
    case "edit":
      return oneLine(args.path ?? args.file_path);
    case "bash":
      return oneLine(args.command);
    case "codemode":
      return oneLine(args.code);
    default:
      return Object.entries(args)
        .map(([key, value]) => `${key}=${typeof value === "string" ? value : json(value)}`)
        .map(oneLine)
        .join(" ");
  }
}

function styledPreview(tool: string, args: Record<string, unknown>, theme: Theme): string {
  const summary = preview(tool, args);
  if (!summary) return "";
  // Highlight before flattening so a leading comment doesn't color the entire preview.
  const styled =
    tool === "codemode"
      ? highlightCode(clean(args.code), "javascript").join(" ").replace(/\s+/g, " ").trim()
      : summary;
  return theme.fg("text", styled);
}

function nestedPreview(call: NestedCall, theme: Theme): string {
  const args = call.args.trimStart();
  if (args.startsWith("{") || args.startsWith("[")) {
    // Codemode stores at most 200 characters of JSON, often cutting off a string or object.
    // Recover the available fields, then use exactly the same rules as the top-level header.
    return styledPreview(call.name, asArgs(parseStreamingJson(args)), theme);
  }
  // Model calls use a provider/model string rather than JSON tool arguments.
  return theme.fg("text", oneLine(call.args));
}

function textOutput(result: Result | undefined, codemode: boolean): string {
  if (!result) return "";
  return result.content
    .filter((block) => block.type === "text")
    .map((block) => {
      const text = clean(block.type === "text" ? block.text : "");
      return codemode
        ? text.replace(/^Script (?:completed|failed)\nWall time [\d.]+ seconds\nOutput:\n/, "")
        : text;
    })
    .filter(Boolean)
    .join("\n")
    .trimEnd();
}

/**
 * Keep per-row and per-section expansion, but honor subsequent changes from Pi's
 * expand-all shortcut, which also opens (or closes) every section.
 */
function syncExpansion(tool: string, context: RenderContext): void {
  const state = context.state;
  if (state.expanded === undefined) {
    state.expanded = tool === "edit" || context.expanded;
    state.sectionsExpanded = context.expanded;
  } else if (state.hostExpanded !== context.expanded) {
    state.expanded = context.expanded;
    state.sections = {};
    state.sectionsExpanded = context.expanded;
  }
  state.hostExpanded = context.expanded;
}

function sectionOpen(state: RendererState, name: string): boolean {
  return state.sections?.[name] ?? !!state.sectionsExpanded;
}

/** Click target for each rendered line: the whole tool row, or one of its sections. */
type Fold = { section?: string };

class ToolView implements Component {
  private theme!: Theme;
  private context!: RenderContext;
  private cache?: { width: number; lines: string[]; folds: Fold[] };
  private lastWidth = 0;

  constructor(
    private readonly tool: string,
    private readonly formatter: FormatCode,
  ) {}

  update(theme: Theme, context: RenderContext): void {
    this.theme = theme;
    this.context = context;
    this.invalidate();
    syncExpansion(this.tool, context);
    const args = asArgs(context.args);
    const code = typeof args.code === "string" ? args.code : "";
    if (
      this.tool === "codemode" &&
      context.state.expanded &&
      sectionOpen(context.state, "code") &&
      (context.argsComplete || !context.isPartial) &&
      code &&
      context.state.format?.code !== code
    ) {
      const request = { code, value: undefined as string | undefined };
      context.state.format = request;
      void this.formatter(code, context.cwd)
        .catch(() => code)
        .then((value) => {
          if (context.state.format !== request) return;
          request.value = value;
          context.invalidate();
        });
    }
  }

  invalidate(): void {
    this.cache = undefined;
  }

  handleMouse(event: TuiMouseEvent) {
    if (event.type !== "click" || event.button !== "left") return undefined;
    // Map the clicked line even if the view was invalidated since the last paint.
    const width = event.width || this.lastWidth;
    if (width && this.cache?.width !== width) this.render(width);
    const state = this.context.state;
    // Toggle the innermost fold containing the clicked line.
    const section = this.cache?.folds[event.y ?? 0]?.section;
    if (section) {
      state.sections = {
        ...state.sections,
        [section]: !sectionOpen(state, section),
      };
    } else {
      state.expanded = !state.expanded;
    }
    this.context.invalidate();
    return { handled: true };
  }

  render(width: number): string[] {
    if (this.cache?.width === width) return this.cache.lines;
    if (width <= 0) return [];
    this.lastWidth = width;
    const { state, args, outputPad, isError } = this.context;
    const theme = this.theme;
    const pad = " ".repeat(Math.min(outputPad, Math.max(0, width - 1)));
    const available = width - pad.length;
    const lines: string[] = [];
    const folds: Fold[] = [];
    let fold: Fold = {};
    const push = (line: string) => {
      lines.push(line);
      folds.push(fold);
    };
    const expanded = state.expanded ?? false;
    const appendPreview = (line: string, indent = 0) => {
      push(truncateToWidth(`${pad}${" ".repeat(indent)}${line}`, width, "…"));
    };
    // Wrap inside the indentation, so continuation lines never return to column zero.
    const body = (value: string, highlighted = false, depth = 2) => {
      const indent = " ".repeat(Math.min(depth, Math.max(0, available - 1)));
      const contentWidth = Math.max(1, available - indent.length);
      // Preserve ANSI only from Pi's code/diff renderers, never from tool output.
      const content = highlighted ? value : clean(value);
      for (const line of content.trimEnd().split("\n")) {
        const text = theme.fg("text", line);
        for (const wrapped of wrapTextWithAnsi(text, contentWidth)) {
          push(truncateToWidth(`${pad}${indent}${wrapped}`, width, ""));
        }
      }
    };
    /** A foldable section: a one-line preview when closed, `renderOpen` contents when open. */
    const section = (name: string, summary: string, renderOpen: () => void) => {
      const open = sectionOpen(state, name);
      push("");
      fold = { section: name };
      let header = theme.fg("muted", `${open ? EXPANDED : COLLAPSED} ${name}`);
      if (!open && summary) header += ` ${summary}`;
      appendPreview(header, 2);
      if (!open) return;
      push("");
      renderOpen();
    };
    const textSection = (name: string, summary: string, value: () => string, highlighted = false) =>
      section(name, summary, () => body(value(), highlighted, 4));
    const outputSection = (output: string) =>
      textSection("output", theme.fg(isError ? "error" : "text", oneLine(output)), () => output);
    const toolArgs = asArgs(args);
    let header = theme.fg("muted", `${expanded ? EXPANDED : COLLAPSED} ${this.tool}`);
    const pathTool = ["read", "write", "edit"].includes(this.tool);
    if (!expanded || pathTool) {
      const summary = styledPreview(this.tool, toolArgs, theme);
      if (summary) header += ` ${summary}`;
    }
    if (isError && !expanded) header += theme.fg("error", " [error]");
    appendPreview(header);

    const output = textOutput(state.result, this.tool === "codemode");
    if (this.tool === "codemode") {
      const details = state.result?.details as CodemodeToolDetails | undefined;
      const calls = details?.calls ?? [];
      // Nested-call statuses belong to the row itself, in both collapsed and expanded states.
      if (calls.length > 0) push("");
      for (const call of calls) {
        const [icon, statusColor] = statusStyle(call);
        appendPreview(
          `${theme.fg(statusColor, icon)} ${theme.fg("muted", oneLine(call.name))} ${nestedPreview(call, theme)}`,
          2,
        );
      }
      if (expanded) {
        textSection(
          "code",
          styledPreview("codemode", toolArgs, theme),
          () => {
            const code = clean(toolArgs.code);
            const formatting = state.format?.code === toolArgs.code ? state.format : undefined;
            if (!this.context.argsComplete && this.context.isPartial) return "Receiving code…";
            if (formatting && formatting.value === undefined) return "Formatting code…";
            return highlightCode(clean(formatting?.value ?? code), "javascript").join("\n");
          },
          true,
        );
        outputSection(output);
      }
    } else if (expanded) {
      switch (this.tool) {
        case "read":
          push("");
          body(output);
          break;
        case "write":
          push("");
          body(isError ? output : clean(toolArgs.content));
          break;
        case "edit": {
          push("");
          const diff = (state.result?.details as { diff?: string } | undefined)?.diff;
          if (!isError && diff) body(renderDiff(clean(diff)), true);
          else body(output);
          break;
        }
        case "bash":
          textSection("command", styledPreview("bash", toolArgs, theme), () =>
            clean(toolArgs.command),
          );
          outputSection(output);
          break;
        default:
          textSection("input", styledPreview(this.tool, toolArgs, theme), () =>
            json(toolArgs, true),
          );
          outputSection(output);
      }
    }
    this.cache = { width, lines, folds };
    return lines;
  }
}

function statusStyle(call: NestedCall): [string, "warning" | "success" | "error" | "muted"] {
  switch (call.status) {
    case "running":
      return ["…", "warning"];
    case "ok":
      return ["✓", "success"];
    case "error":
      return ["✗", "error"];
    case "cancelled":
      return ["⊘", "muted"];
    default:
      return ["?", "muted"];
  }
}

export function createToolRenderers(
  tool: string,
  formatter: FormatCode = formatCode,
): ToolRenderers {
  return {
    renderShell: "self",
    renderCall(_args, theme, context: RenderContext) {
      const view =
        context.lastComponent instanceof ToolView
          ? context.lastComponent
          : new ToolView(tool, formatter);
      view.update(theme, context);
      return view;
    },
    renderResult(result, _options, _theme, context: RenderContext) {
      // The call component reads this at render time, keeping tools/code/output in one layout.
      context.state.result = result;
      return EMPTY;
    },
  };
}

export default function compactOutput(pi: ExtensionAPI): void {
  pi.registerToolRenderer((toolName) => createToolRenderers(toolName));
  let disposePanels: (() => void) | undefined;
  pi.on("session_start", (_event, ctx) => {
    disposePanels?.();
    disposePanels = ctx.mode === "tui" ? installAssistantPanels(() => ctx.ui.theme) : undefined;
  });
  pi.on("session_shutdown", () => {
    disposePanels?.();
    disposePanels = undefined;
  });
}
