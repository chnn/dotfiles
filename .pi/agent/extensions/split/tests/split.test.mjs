import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { mkdtemp, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

// Exercise the installed Pi SDK rather than keeping a duplicate dependency tree.
function findPi() {
  if (process.env.PI_PACKAGE_ROOT) return process.env.PI_PACKAGE_ROOT;
  try {
    return path.dirname(path.dirname(createRequire(import.meta.url).resolve("@earendil-works/pi-coding-agent")));
  } catch {}
  let executable;
  try {
    executable = execFileSync("volta", ["which", "pi"], { encoding: "utf8" }).trim();
  } catch {
    executable = execFileSync("which", ["pi"], { encoding: "utf8" }).trim();
  }
  let root = path.dirname(realpathSync(executable));
  while (!existsSync(path.join(root, "package.json"))) {
    const parent = path.dirname(root);
    if (parent === root) throw new Error("Set PI_PACKAGE_ROOT to the installed Pi package directory.");
    root = parent;
  }
  return root;
}
const root = findPi();
const requirePi = createRequire(path.join(root, "package.json"));
const { createJiti } = await import(pathToFileURL(requirePi.resolve("jiti")));
const { SessionManager } = await import(pathToFileURL(path.join(root, "dist/index.js")));
const theme = await import(pathToFileURL(path.join(root, "dist/modes/interactive/theme/theme.js")));
const tui = await import(pathToFileURL(requirePi.resolve("@earendil-works/pi-tui")));
theme.initTheme("dark", false);
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-coding-agent": path.join(root, "dist/index.js"),
    "@earendil-works/pi-tui": requirePi.resolve("@earendil-works/pi-tui"),
  },
});
const extensionPath = fileURLToPath(new URL("../index.ts", import.meta.url));
const { default: extension, splitPoint, createSplitSession, buildRexArgs } = await jiti.import(extensionPath);

async function fixture(t) {
  const cwd = await mkdtemp(path.join(tmpdir(), "pi-split-test-"));
  t.after(() => rm(cwd, { recursive: true, force: true }));
  const source = SessionManager.create(cwd, path.join(cwd, "sessions with spaces"));
  const setup = source.appendThinkingLevelChange("high");
  const first = source.appendMessage({ role: "user", content: "First prompt", timestamp: 1 });
  const second = source.appendMessage({ role: "user", content: "Second prompt\nwith a draft", timestamp: 2 });
  const third = source.appendMessage({ role: "user", content: "Later prompt", timestamp: 3 });
  return { cwd, source, setup, first, second, third };
}

function unchanged(source) {
  const before = JSON.stringify([source.getHeader(), source.getEntries(), source.getLeafId(), source.getSessionFile()]);
  return () => assert.equal(
    JSON.stringify([source.getHeader(), source.getEntries(), source.getLeafId(), source.getSessionFile()]), before,
  );
}

test("user/custom prompts become drafts; all other entries are inclusive", () => {
  assert.deepEqual(splitPoint({ type: "message", id: "u", parentId: null,
    message: { role: "user", content: [{ type: "text", text: "a" }, { type: "image" }, { type: "text", text: "b" }] },
  }), { leafId: null, draft: "ab" });
  assert.deepEqual(splitPoint({ type: "custom_message", id: "c", parentId: "a", content: "prefill" }),
    { leafId: "a", draft: "prefill" });
  assert.deepEqual(splitPoint({ type: "message", id: "a", message: { role: "assistant" } }), { leafId: "a" });
});

test("fork is independently persisted at the chosen point; source bytes and live state stay unchanged", async (t) => {
  const { source, cwd, first, second } = await fixture(t);
  const check = unchanged(source);
  const original = await readFile(source.getSessionFile(), "utf8");
  const fork = await createSplitSession(source, cwd, second);
  const child = SessionManager.open(fork.sessionFile);
  assert.notEqual(child.getSessionId(), source.getSessionId());
  assert.equal(child.getHeader().parentSession, source.getSessionFile());
  assert.equal(child.getHeader().cwd, cwd);
  assert.equal(child.getLeafId(), first);
  assert.equal(fork.draft, "Second prompt\nwith a draft");
  assert.equal(child.getEntries().some((e) => e.id === second), false);
  assert.equal((await stat(fork.sessionFile)).mode & 0o777, 0o600);
  child.appendMessage({ role: "user", content: "Child only", timestamp: 4 });
  assert.equal(await readFile(source.getSessionFile(), "utf8"), original);
  check();
});

test("setup-only and empty-root forks are flushed even without a conversation", async (t) => {
  const { source, cwd, first, setup } = await fixture(t);
  const fork = await createSplitSession(source, cwd, first);
  assert.deepEqual(SessionManager.open(fork.sessionFile).getEntries().map((e) => e.id), [setup]);
  assert.equal(fork.draft, "First prompt");
  const memory = SessionManager.inMemory(cwd);
  // Keep the persisted child of this ephemeral source inside the test fixture too.
  memory.getSessionDir = () => source.getSessionDir();
  const rootUser = memory.appendMessage({ role: "user", content: "Root draft", timestamp: 1 });
  const empty = await createSplitSession(memory, cwd, rootUser);
  assert.deepEqual(SessionManager.open(empty.sessionFile).getEntries(), []);
  assert.equal(empty.draft, "Root draft");
  assert.equal(SessionManager.open(empty.sessionFile).getHeader().parentSession, undefined);
});

test("inactive branches, resolved labels, and parent links survive without copying abandoned history", async (t) => {
  const { source, cwd, first, second, third } = await fixture(t);
  source.appendLabelChange(first, "bookmark");
  source.branch(first);
  const alternate = source.appendMessage({ role: "user", content: "Alternate", timestamp: 4 });
  const check = unchanged(source);
  const fork = await createSplitSession(source, cwd, third);
  const child = SessionManager.open(fork.sessionFile);
  assert.equal(child.getLabel(first), "bookmark");
  assert.ok(child.getEntry(second));
  assert.equal(child.getEntry(third), undefined);
  assert.equal(child.getEntry(alternate), undefined);
  for (const entry of child.getEntries()) {
    assert.ok(entry.parentId === null || child.getEntry(entry.parentId));
  }
  check();
});

test("invalid entry fails without creating a fork", async (t) => {
  const { source, cwd } = await fixture(t);
  const before = await readdir(source.getSessionDir());
  await assert.rejects(createSplitSession(source, cwd, "missing"), /no longer exists/);
  assert.deepEqual(await readdir(source.getSessionDir()), before);
});

test("Rex argv targets the inherited block, goes right, resumes the fork, and never submits draft text", () => {
  const args = buildRexArgs({ rexSession: "session:original", rexBlock: "block:original", cwd: "/work dir",
    sessionFile: "/fork dir/new.jsonl", sessionDir: "/fork dir", model: { provider: "provider", id: "model" },
    thinkingLevel: "high", draftFile: "/fork dir/draft",
  });
  assert.deepEqual(args.slice(0, 11), ["split", "--session", "session:original", "--block", "block:original",
    "--split=right", "--cwd", "/work dir", "--shell=none", "--json", "--"]);
  const child = args.slice(args.indexOf("--") + 1);
  assert.ok(child.includes(process.execPath));
  assert.ok(child.includes(path.join(root, "dist/bundle/cli.js")));
  assert.equal(child[child.indexOf("--session") + 1], "/fork dir/new.jsonl");
  assert.equal(child[child.indexOf("--model") + 1], "model");
  assert.ok(!child.includes("--fork") && !child.includes("--continue") && !args.includes("--wait"));
  assert.equal(child[child.indexOf("--split-draft") + 1], "/fork dir/draft");
});

function harness(source, options = {}) {
  let handler;
  let onStart;
  const notices = [];
  const calls = [];
  const editor = [];
  extension({
    registerFlag() {}, getFlag: () => options.draftFile,
    on: (name, callback) => { if (name === "session_start") onStart = callback; },
    getSettings: () => ({}),
    registerCommand: (name, command) => { assert.equal(name, "split"); handler = command.handler; },
    exec: async (command, args) => {
      calls.push({ command, args });
      if (options.fail && args[0] === options.fail) return { code: 1, stdout: "", stderr: "Rex unavailable" };
      return { code: 0, stdout: "{}", stderr: "" };
    },
  });
  const ctx = {
    mode: options.mode ?? "tui", sessionManager: source, cwd: source.getCwd(),
    thinkingLevel: "high", model: { provider: "provider", id: "model" },
    ui: {
      notify: (message, level) => notices.push({ message, level }),
      setEditorText: (text) => editor.push(text),
      custom: async (factory, uiOptions) => {
        assert.equal(uiOptions.overlay, true);
        assert.equal(uiOptions.blocked.kind, "question");
        let selected;
        const view = factory({ terminal: { rows: 40 } }, theme.theme, {}, (value) => { selected = value; });
        view.focused = true;
        for (const width of [24, 80]) assert.ok(view.render(width).every((line) => tui.visibleWidth(line) <= width));
        assert.equal(view.getTreeList().onLabelEdit, undefined);
        if (options.select) view.getTreeList().onSelect(options.select);
        else view.getTreeList().onCancel();
        return selected;
      },
    },
  };
  return { run: () => handler("", ctx), start: (reason = "startup") => onStart({ reason }, ctx), notices, calls, editor };
}

function withRex(t) {
  const previous = { session: process.env.REX_SESSION, block: process.env.REX_BLOCK };
  t.after(() => {
    for (const [key, value] of [["REX_SESSION", previous.session], ["REX_BLOCK", previous.block]]) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
  });
  process.env.REX_SESSION = "session:test";
  process.env.REX_BLOCK = "block:test";
}

test("command uses native selector, preflights anchor, opens right pane, and never modifies this editor/session", async (t) => {
  withRex(t);
  const { source, second } = await fixture(t);
  const check = unchanged(source);
  const h = harness(source, { select: second });
  await h.run();
  assert.deepEqual(h.calls.map((call) => call.args[0]), ["block", "split"]);
  // block inspect includes huge method schemas; use the bounded process query.
  assert.deepEqual(h.calls[0].args, ["block", "call", "--session", "session:test",
    "--block", "block:test", "process"]);
  const args = h.calls[1].args;
  const draftFile = args[args.indexOf("--split-draft") + 1];
  assert.equal(await readFile(draftFile, "utf8"), "Second prompt\nwith a draft");
  assert.equal((await stat(draftFile)).mode & 0o777, 0o600);
  assert.deepEqual(h.editor, []);
  assert.match(h.notices.at(-1).message, /Opened the fork/);
  check();
});

test("cancel, non-TUI, missing Rex, empty sessions, and stale anchors do not create forks", async (t) => {
  withRex(t);
  const { source, second } = await fixture(t);
  const before = await readdir(source.getSessionDir());
  const cancel = harness(source);
  await cancel.run();
  assert.deepEqual(cancel.calls, []);
  const rpc = harness(source, { mode: "rpc" });
  await rpc.run();
  assert.match(rpc.notices[0].message, /interactive terminal/);
  const stale = harness(source, { select: second, fail: "block" });
  await stale.run();
  assert.equal(stale.calls.length, 1);
  assert.match(stale.notices[0].message, /Rex unavailable/);
  delete process.env.REX_BLOCK;
  const noRex = harness(source);
  await noRex.run();
  assert.match(noRex.notices[0].message, /inside Rex/);
  process.env.REX_BLOCK = "block:test";
  const empty = harness(SessionManager.inMemory(source.getCwd()));
  await empty.run();
  assert.match(empty.notices[0].message, /no session entries/);
  assert.deepEqual(await readdir(source.getSessionDir()), before);
});

test("failed split retains the fork/draft for recovery and never retries", async (t) => {
  withRex(t);
  const { source, second } = await fixture(t);
  const check = unchanged(source);
  const h = harness(source, { select: second, fail: "split" });
  await h.run();
  assert.equal(h.calls.length, 2);
  assert.match(h.notices.at(-1).message, /Fork saved at .*check Rex before retrying/);
  const args = h.calls[1].args;
  const childArgs = args.slice(args.indexOf("--") + 1);
  assert.ok(existsSync(childArgs[childArgs.indexOf("--session") + 1]));
  check();
});

test("child startup restores the draft exactly once without starting a turn, then removes handoff", async (t) => {
  const { source, cwd } = await fixture(t);
  const draftFile = path.join(cwd, "draft");
  const draft = "A draft\nwith 'quotes' and $shell syntax";
  await writeFile(draftFile, draft);
  const h = harness(source, { draftFile });
  await h.start();
  assert.deepEqual(h.editor, [draft]);
  assert.equal(existsSync(draftFile), false);
  await h.start("reload");
  await h.start("resume");
  await h.start();
  assert.deepEqual(h.editor, [draft]);
  assert.deepEqual(h.calls, []);
});
