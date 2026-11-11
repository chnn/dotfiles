/** Fork a selected session point into a Rex block to the right, without navigating here. */
import { readFile, unlink, writeFile } from "node:fs/promises";
import { realpathSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  copyToClipboard,
  getAgentDir,
  getPackageDir,
  SessionManager,
  TreeSelectorComponent,
  type ExtensionAPI,
  type ExtensionContext,
  type SessionEntry,
} from "@earendil-works/pi-coding-agent";

const DRAFT_FLAG = "split-draft";
const extensionPath = realpathSync(fileURLToPath(import.meta.url));

type SessionReader = ExtensionContext["sessionManager"];

function textContent(content: string | { type: string; text?: string }[]): string {
  return typeof content === "string"
    ? content
    : content.filter((part) => part.type === "text").map((part) => part.text ?? "").join("");
}

/** Match /tree: user/custom prompts go back into the editor; other entries are inclusive. */
export function splitPoint(entry: SessionEntry): { leafId: string | null; draft?: string } {
  if (entry.type === "message" && entry.message.role === "user") {
    return { leafId: entry.parentId, draft: textContent(entry.message.content) };
  }
  if (entry.type === "custom_message") {
    return { leafId: entry.parentId, draft: textContent(entry.content) };
  }
  return { leafId: entry.id };
}

/** Never open the source file: even loading a legacy file can migrate/rewrite it. */
export async function createSplitSession(source: SessionReader, cwd: string, entryId: string) {
  const entries = structuredClone(source.getEntries());
  const selected = entries.find((entry) => entry.id === entryId);
  if (!selected) throw new Error(`Session entry ${entryId} no longer exists.`);
  const point = splitPoint(selected);
  const header = source.getHeader();
  const snapshot = SessionManager.inMemory(
    cwd,
    undefined,
    header ? [structuredClone(header), ...entries] : entries,
  );
  if (point.leafId !== null) snapshot.createBranchedSession(point.leafId);

  // Use Pi's filename/header allocation, but write explicitly: setup-only forks are
  // otherwise unflushed and would lose their history when the child opens the file.
  const destination = SessionManager.create(cwd, source.getSessionDir() || undefined, {
    parentSession: source.getSessionFile(),
  });
  const sessionFile = destination.getSessionFile()!;
  const forkEntries = point.leafId === null ? [] : snapshot.getEntries();
  await writeFile(
    sessionFile,
    [destination.getHeader(), ...forkEntries].map((entry) => JSON.stringify(entry)).join("\n") + "\n",
    { flag: "wx", mode: 0o600 },
  );
  return { sessionFile, sessionDir: destination.getSessionDir(), draft: point.draft };
}

export function buildRexArgs(options: {
  rexSession: string;
  rexBlock: string;
  cwd: string;
  sessionFile: string;
  sessionDir: string;
  model?: { provider: string; id: string };
  thinkingLevel: string;
  draftFile?: string;
}): string[] {
  const args = [
    "split", "--session", options.rexSession, "--block", options.rexBlock,
    "--split=right", "--cwd", options.cwd, "--shell=none", "--json",
    "--", "env", `PI_CODING_AGENT_DIR=${getAgentDir()}`,
    process.execPath, join(getPackageDir(), "dist", "bundle", "cli.js"),
    "--session", options.sessionFile, "--session-dir", options.sessionDir,
    "--extension", extensionPath,
  ];
  if (options.model) args.push("--provider", options.model.provider, "--model", options.model.id);
  args.push("--thinking", options.thinkingLevel);
  if (options.draftFile) args.push(`--${DRAFT_FLAG}`, options.draftFile);
  return args;
}

export default function splitExtension(pi: ExtensionAPI) {
  // A file keeps potentially large/private prompts out of argv. Only the new Pi
  // consumes this one-shot handoff; it prefills the editor, never sends a prompt.
  pi.registerFlag(DRAFT_FLAG, {
    description: "Internal /split draft handoff file",
    type: "string",
  });
  let draftHandled = false;
  pi.on("session_start", async (event, ctx) => {
    if (draftHandled || event.reason !== "startup" || ctx.mode !== "tui") return;
    draftHandled = true;
    const draftFile = pi.getFlag(DRAFT_FLAG);
    if (typeof draftFile !== "string" || !draftFile) return;
    try {
      ctx.ui.setEditorText(await readFile(draftFile, "utf8"));
      await unlink(draftFile);
    } catch (error) {
      ctx.ui.notify(`Could not restore split draft (${draftFile}): ${String(error)}`, "error");
    }
  });

  let splitting = false;
  pi.registerCommand("split", {
    description: "Fork a session point into a Rex block on the right (keep this session)",
    handler: async (_args, ctx) => {
      if (ctx.mode !== "tui") {
        ctx.ui.notify("/split requires Pi's interactive terminal UI.", "error");
        return;
      }
      const rexSession = process.env.REX_SESSION;
      const rexBlock = process.env.REX_BLOCK;
      if (!rexSession || !rexBlock) {
        ctx.ui.notify("/split must run inside Rex (REX_SESSION and REX_BLOCK are required).", "error");
        return;
      }
      if (splitting) return;
      splitting = true;
      let sessionFile: string | undefined;
      try {
        const source = ctx.sessionManager;
        const tree = structuredClone(source.getTree());
        if (tree.length === 0) {
          ctx.ui.notify("There are no session entries to split from yet.", "warning");
          return;
        }
        const selected = await ctx.ui.custom<string | undefined>(
          (tui, _theme, _keybindings, done) => {
            const selector = new TreeSelectorComponent(
              tree, source.getLeafId(), tui.terminal.rows,
              (id) => done(id), () => done(undefined), undefined, undefined,
              pi.getSettings().treeFilterMode ?? "default",
            );
            // A picker must not let label editing mutate the current session.
            selector.getTreeList().onLabelEdit = undefined;
            selector.onCopy = (text) => { if (text) copyToClipboard(text); };
            return selector;
          },
          {
            overlay: true,
            overlayOptions: { width: "100%", anchor: "bottom-left" },
            blocked: { kind: "question", message: "Choose a point to split into a new Rex pane" },
          },
        );
        if (!selected) return;

        // Validate the inherited anchor before writing any fork files. Never fall
        // back to Rex's focused block, which might belong to an unrelated task.
        const anchor = await pi.exec("rex", [
          "block", "call", "--session", rexSession, "--block", rexBlock, "process",
        ], { timeout: 15_000, maxBuffer: 64 * 1024 });
        if (anchor.code !== 0) throw new Error(anchor.stderr.trim() || "Rex could not find this block.");

        const fork = await createSplitSession(source, ctx.cwd, selected);
        sessionFile = fork.sessionFile;
        let draftFile: string | undefined;
        if (fork.draft) {
          draftFile = `${sessionFile}.split-draft`;
          await writeFile(draftFile, fork.draft, { flag: "wx", mode: 0o600 });
        }
        const result = await pi.exec("rex", buildRexArgs({
          rexSession, rexBlock, cwd: ctx.cwd,
          sessionFile, sessionDir: fork.sessionDir, draftFile,
          model: ctx.model, thinkingLevel: ctx.thinkingLevel ?? pi.getThinkingLevel(),
        }), { timeout: 20_000, maxBuffer: 64 * 1024 });
        if (result.code !== 0) {
          throw new Error(result.stderr.trim() || result.stdout.trim() || "Rex split failed.");
        }
        ctx.ui.notify("Opened the fork in a Rex block to the right. This session is unchanged.", "info");
      } catch (error) {
        // Retain the fork on failure: a timed-out Rex request may still have
        // opened a child. Do not delete its session or retry and create duplicates.
        const recovery = sessionFile ? ` Fork saved at ${sessionFile}; check Rex before retrying.` : "";
        ctx.ui.notify(`/split failed: ${String(error)}${recovery}`, "error");
      } finally {
        splitting = false;
      }
    },
  });
}
