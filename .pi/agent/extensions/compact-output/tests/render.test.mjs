import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

// Test against the installed Pi packages, without installing duplicate host dependencies.
function findPi() {
  if (process.env.PI_PACKAGE_ROOT) return process.env.PI_PACKAGE_ROOT;
  try {
    return path.dirname(
      path.dirname(createRequire(import.meta.url).resolve("@earendil-works/pi-coding-agent")),
    );
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
    if (parent === root)
      throw new Error("Set PI_PACKAGE_ROOT to your installed pi-coding-agent directory.");
    root = parent;
  }
  return root;
}

const root = findPi();
const requirePi = createRequire(path.join(root, "package.json"));
const { createJiti } = await import(pathToFileURL(requirePi.resolve("jiti")));
const tui = await import(pathToFileURL(requirePi.resolve("@earendil-works/pi-tui")));
const themeModule = await import(
  pathToFileURL(path.join(root, "dist/modes/interactive/theme/theme.js"))
);
themeModule.initTheme("dark", false);
const jiti = createJiti(import.meta.url, {
  alias: {
    "@earendil-works/pi-ai": path.join(root, "node_modules/@earendil-works/pi-ai/dist/compat.js"),
    "@earendil-works/pi-tui": requirePi.resolve("@earendil-works/pi-tui"),
    "@earendil-works/pi-coding-agent": path.join(root, "dist/index.js"),
  },
});
const extensionPath = fileURLToPath(new URL("../index.ts", import.meta.url));
const { default: extension, createToolRenderers, formatCode } = await jiti.import(extensionPath);
const { installAssistantPanels } = await jiti.import(
  fileURLToPath(new URL("../assistant-panels.ts", import.meta.url)),
);
const { AssistantMessageComponent } = await import(
  pathToFileURL(path.join(root, "dist/modes/interactive/components/assistant-message.js"))
);
const theme = { fg: (_color, value) => value, bg: (_color, value) => value };
const result = (text, details) => ({ content: [{ type: "text", text }], details });

function row(tool, args, options = {}) {
  const renderers = createToolRenderers(tool, options.formatter ?? (async (code) => code));
  const context = {
    args,
    state: {},
    toolCallId: "test-id",
    cwd: process.cwd(),
    expanded: false,
    argsComplete: true,
    executionStarted: true,
    isPartial: false,
    isError: false,
    showImages: false,
    outputPad: 0,
    ...options,
  };
  let view;
  let currentResult;
  const update = () => {
    const activeTheme = options.theme
      ? {
          fg: options.theme.fg.bind(options.theme),
          bg: options.theme.bg?.bind(options.theme) ?? theme.bg,
        }
      : theme;
    view = renderers.renderCall(args, activeTheme, { ...context, lastComponent: view });
    if (currentResult) renderers.renderResult(currentResult, context, activeTheme, context);
  };
  context.invalidate = update;
  update();
  return {
    render: (width = 80) =>
      view.render(width).map((line) => tui.stripTerminalSequences(line).trimEnd()),
    renderStyled: (width = 80) => view.render(width),
    result(value, isPartial = false) {
      currentResult = value;
      context.isPartial = isPartial;
      update();
    },
    expand(expanded) {
      context.expanded = expanded;
      update();
    },
    click(y = 0) {
      return view.handleMouse({ type: "click", button: "left", y });
    },
    context,
  };
}

for (const tool of ["read", "write", "edit"]) {
  test(`${tool}: path header and indented expanded content`, () => {
    const view = row(tool, { path: "file.ext", content: "written\ncontents" });
    view.result(result("read\ncontents", { diff: "-old\n+new" }));
    if (tool !== "edit") assert.deepEqual(view.render(), [` ${tool} file.ext`]);
    view.expand(true);
    const contents =
      tool === "write"
        ? ["written", "contents"]
        : tool === "edit"
          ? ["-old", "+new"]
          : ["read", "contents"];
    assert.deepEqual(view.render(), [
      ` ${tool} file.ext`,
      "",
      ...contents.map((line) => `  ${line}`),
    ]);
  });
}

test("previews use the text token while tool names remain muted", () => {
  const grayTheme = {
    fg: (color, value) => `\x1b[${color === "muted" ? "90" : "37"}m${value}\x1b[39m`,
  };
  const read = row("read", { path: "file.ext" }, { theme: grayTheme });
  assert.ok(read.renderStyled()[0].includes("\x1b[90m read\x1b[39m"));
  assert.ok(read.renderStyled()[0].includes("\x1b[37mfile.ext\x1b[39m"));
  const code = row("codemode", { code: "return 1;" }, { theme: grayTheme });
  code.result(
    result("", { calls: [{ id: "1", name: "read", args: '{"path":"nested.ext"}', status: "ok" }] }),
  );
  assert.ok(code.renderStyled()[0].includes(themeModule.theme.fg("syntaxKeyword", "return")));
  assert.ok(code.renderStyled()[2].includes("\x1b[90mread\x1b[39m"));
  assert.ok(code.renderStyled()[2].includes("\x1b[37mnested.ext\x1b[39m"));
});

test("expanded plain outputs and errors use text; labels use muted", () => {
  const tokens = [];
  const recordingTheme = {
    fg: (token, value) => {
      tokens.push([token, value]);
      return value;
    },
  };
  const bash = row(
    "bash",
    { command: "echo hi" },
    { expanded: true, isError: true, theme: recordingTheme },
  );
  bash.result(result("failed"));
  bash.render();
  assert.ok(tokens.some(([token, value]) => token === "muted" && value === " command"));
  assert.ok(tokens.some(([token, value]) => token === "muted" && value === " output"));
  assert.ok(tokens.some(([token, value]) => token === "text" && value === "echo hi"));
  assert.ok(tokens.some(([token, value]) => token === "text" && value === "failed"));
  assert.ok(tokens.every(([token]) => token !== "toolOutput"));
});

test("edit uses Pi's diff highlighting, including changed words, across theme changes", () => {
  const view = row("edit", { path: "file.ext" }, { theme: themeModule.theme });
  view.result(result("Applied", { diff: " 1 unchanged\n-2 old value\n+2 new value" }));
  const dark = view.renderStyled().join("\n");
  assert.ok(dark.includes(themeModule.theme.getFgAnsi("toolDiffRemoved")));
  assert.ok(dark.includes(themeModule.theme.getFgAnsi("toolDiffAdded")));
  assert.ok(dark.includes(themeModule.theme.getFgAnsi("toolDiffContext")));
  assert.ok(dark.includes(themeModule.theme.inverse("old")));
  assert.ok(dark.includes(themeModule.theme.inverse("new")));
  assert.deepEqual(view.render().slice(2), ["   1 unchanged", "  -2 old value", "  +2 new value"]);
  for (const width of [8, 20]) {
    const lines = view.renderStyled(width);
    assert.ok(lines.every((line) => tui.visibleWidth(line) <= width));
    assert.ok(lines.slice(2).every((line) => tui.stripTerminalSequences(line).startsWith("  ")));
  }
  try {
    themeModule.initTheme("light", false);
    view.context.invalidate();
    const light = view.renderStyled().join("\n");
    assert.ok(light.includes(themeModule.theme.getFgAnsi("toolDiffAdded")));
    assert.notEqual(light, dark);
  } finally {
    themeModule.initTheme("dark", false);
  }
});

test("tool blocks never apply backgrounds in collapsed or expanded modes", () => {
  const framelessTheme = {
    fg: themeModule.theme.fg.bind(themeModule.theme),
    bg() {
      assert.fail("Tool backgrounds should not be applied");
    },
  };
  for (const options of [{ isPartial: true }, {}, { isError: true }]) {
    const view = row("bash", { command: "echo hi" }, { ...options, theme: framelessTheme });
    view.result(result("output\n" + "界".repeat(30)), options.isPartial ?? false);
    for (const expanded of [false, true]) {
      view.expand(expanded);
      for (const width of [1, 4, 20, 80]) {
        const lines = view.renderStyled(width);
        assert.ok(lines.every((line) => tui.visibleWidth(line) <= width));
        assert.ok(lines.every((line) => !line.includes("\x1b[49m")));
      }
    }
  }
});

test("collapsed codemode previews are highlighted, flattened, and truncated without formatting", () => {
  let formats = 0;
  const code = '// comment\nconst value = "界";\nreturn value;';
  const view = row(
    "codemode",
    { code },
    {
      isPartial: true,
      argsComplete: false,
      formatter: async () => {
        formats++;
        return code;
      },
    },
  );
  const dark = view.renderStyled()[0];
  assert.ok(dark.includes(themeModule.theme.fg("syntaxComment", "// comment")));
  assert.ok(dark.includes(themeModule.theme.fg("syntaxKeyword", "const")));
  assert.ok(dark.includes(themeModule.theme.fg("syntaxString", '\"界\"')));
  assert.deepEqual(view.render(), [' codemode // comment const value = "界"; return value;']);
  for (const width of [1, 4, 20, 80]) {
    const lines = view.renderStyled(width);
    assert.equal(lines.length, 1);
    assert.ok(tui.visibleWidth(lines[0]) <= width);
    assert.ok(!lines[0].includes("\n"));
  }
  assert.equal(formats, 0);
  try {
    themeModule.initTheme("light", false);
    view.context.invalidate();
    const light = view.renderStyled()[0];
    assert.ok(light.includes(themeModule.theme.fg("syntaxKeyword", "const")));
    assert.notEqual(light, dark);
  } finally {
    themeModule.initTheme("dark", false);
  }
});

test("codemode highlights formatted JavaScript and refreshes syntax colors on theme change", async () => {
  const view = row(
    "codemode",
    { code: "return 'raw';" },
    {
      expanded: true,
      formatter: async () => 'const message = "formatted";\nreturn message;',
    },
  );
  await new Promise((resolve) => setImmediate(resolve));
  const dark = view.renderStyled().join("\n");
  assert.ok(dark.includes(themeModule.theme.fg("syntaxKeyword", "const")));
  assert.ok(dark.includes(themeModule.theme.fg("syntaxString", '\"formatted\"')));
  assert.ok(view.render().includes('    const message = "formatted";'));
  const codeStart = view.render().indexOf("   code") + 2;
  for (const width of [10, 20, 80]) {
    const lines = view.renderStyled(width);
    assert.ok(lines.every((line) => tui.visibleWidth(line) <= width));
    const codeEnd = lines.findIndex(
      (line, i) => i > codeStart && tui.stripTerminalSequences(line).trim().endsWith("output"),
    );
    assert.ok(codeEnd > codeStart);
    assert.ok(
      lines
        .slice(codeStart, codeEnd)
        .filter(Boolean)
        .every((line) => tui.stripTerminalSequences(line).startsWith("    ")),
    );
  }
  try {
    themeModule.initTheme("light", false);
    view.context.invalidate();
    const light = view.renderStyled().join("\n");
    assert.ok(light.includes(themeModule.theme.fg("syntaxKeyword", "const")));
    assert.notEqual(light, dark);
  } finally {
    themeModule.initTheme("dark", false);
  }
});

test("edit starts expanded, is independently collapsible, and honors expand-all", () => {
  const view = row("edit", { path: "file.ext" });
  view.result(result("Applied", { diff: "+new" }));
  assert.deepEqual(view.render(), [" edit file.ext", "", "  +new"]);
  assert.deepEqual(view.click(), { handled: true });
  assert.deepEqual(view.render(), [" edit file.ext"]);
  view.expand(true);
  assert.equal(view.render()[0], " edit file.ext");
  view.expand(false);
  assert.deepEqual(view.render(), [" edit file.ext"]);
});

test("bash separates the complete command and output", () => {
  const view = row("bash", { command: "echo one\necho two" });
  view.result(result("one\ntwo"));
  assert.deepEqual(view.render(), [" bash echo one echo two"]);
  view.expand(true);
  assert.deepEqual(view.render(), [
    " bash",
    "",
    "   command",
    "",
    "    echo one",
    "    echo two",
    "",
    "   output",
    "",
    "    one",
    "    two",
  ]);
});

test("clicking expands the row with folded sections, then each section separately", () => {
  const view = row("bash", { command: "echo one\necho two" });
  view.result(result("one\ntwo"));
  const click = (y) => assert.deepEqual(view.click(y), { handled: true });
  click(0);
  assert.deepEqual(view.render(), [
    " bash",
    "",
    "   command echo one echo two",
    "",
    "   output one two",
  ]);
  click(2);
  assert.deepEqual(view.render(), [
    " bash",
    "",
    "   command",
    "",
    "    echo one",
    "    echo two",
    "",
    "   output one two",
  ]);
  click(7);
  assert.equal(view.render().length, 11);
  // A click inside a section body folds that section only.
  click(4);
  assert.deepEqual(view.render(), [
    " bash",
    "",
    "   command echo one echo two",
    "",
    "   output",
    "",
    "    one",
    "    two",
  ]);
  // Collapsing and re-expanding the row remembers section state.
  click(0);
  assert.deepEqual(view.render(), [" bash echo one echo two"]);
  click(0);
  assert.equal(view.render()[4], "   output");
  // Expand-all opens every section; collapse-all resets them.
  view.expand(true);
  assert.equal(view.render()[2], "   command");
  view.expand(false);
  assert.deepEqual(view.render(), [" bash echo one echo two"]);
  click(0);
  assert.equal(view.render()[2], "   command echo one echo two");
});

test("section previews truncate to the terminal width", () => {
  const long = "界🙂é".repeat(40);
  for (const [tool, args] of [
    ["bash", { command: long }],
    ["codemode", { code: long }],
    ["other", { value: long }],
  ]) {
    const view = row(tool, args, { outputPad: 1 });
    view.result(result(long));
    view.click(0);
    for (const width of [1, 4, 20, 40]) {
      assert.ok(view.renderStyled(width).every((line) => tui.visibleWidth(line) <= width));
    }
  }
});

test("preview rows truncate without wrapping, including Unicode and terminal padding", () => {
  for (const tool of ["read", "write", "bash", "codemode", "other"]) {
    const long = "界🙂é".repeat(40);
    const view = row(
      tool,
      { path: long, command: long, code: long, value: long },
      { outputPad: 1 },
    );
    for (const width of [1, 2, 3, 8, 20, 40]) {
      const lines = view.render(width);
      assert.equal(lines.length, 1);
      assert.ok(
        lines.every((line) => tui.visibleWidth(line) <= width),
        `${tool} width=${width}`,
      );
    }
  }
});

test("all expanded continuation lines retain their indentation across resize", () => {
  const view = row("read", { path: "file" }, { expanded: true, outputPad: 1 });
  view.result(result("界🙂".repeat(30)));
  for (const width of [1, 2, 3, 4, 10, 40]) {
    const lines = view.renderStyled(width).map(tui.stripTerminalSequences);
    assert.ok(lines.every((line) => tui.visibleWidth(line) <= width));
    if (width >= 4) assert.ok(lines.slice(2).every((line) => line.startsWith("   ")));
  }
});

test("codemode streams statuses while collapsed and expands tools/code/output in order", async () => {
  let formats = 0;
  const view = row(
    "codemode",
    { code: "return await tools.read({path:'file'});" },
    {
      formatter: async () => {
        formats++;
        return 'return await tools.read({ path: "file" });';
      },
    },
  );
  const calls = [
    { id: "1", name: "read", args: '{"path":"file"}', status: "running" },
    { id: "2", name: "bash", args: '{"command":"echo hi"}', status: "ok" },
    { id: "3", name: "edit", args: '{"path":"other"}', status: "error" },
    { id: "4", name: "write", args: '{"path":"last"}', status: "cancelled" },
  ];
  view.result(result("", { calls }), true);
  assert.deepEqual(view.render().slice(1), [
    "",
    "  … read file",
    "  ✓ bash echo hi",
    "  ✗ edit other",
    "  ⊘ write last",
  ]);
  assert.equal(formats, 0);
  calls[0] = { ...calls[0], status: "ok" };
  view.result(result("Script completed\nWall time 0.2 seconds\nOutput:\nhello", { calls }));
  assert.equal(view.render()[2], "  ✓ read file");
  view.expand(true);
  assert.ok(view.render().includes("    Formatting code…"));
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(view.render(), [
    " codemode",
    "",
    "  ✓ read file",
    "  ✓ bash echo hi",
    "  ✗ edit other",
    "  ⊘ write last",
    "",
    "   code",
    "",
    '    return await tools.read({ path: "file" });',
    "",
    "   output",
    "",
    "    hello",
  ]);
  view.expand(false);
  view.expand(true);
  assert.equal(formats, 1);
});

test("codemode keeps tool statuses on the row and formats only when code opens", async () => {
  let formats = 0;
  const view = row(
    "codemode",
    { code: "return 1;" },
    {
      formatter: async () => {
        formats++;
        return "return 1;";
      },
    },
  );
  const calls = [{ id: "1", name: "read", args: '{"path":"file"}', status: "ok" }];
  view.result(result("Script completed\nWall time 0.2 seconds\nOutput:\nhello", { calls }));
  assert.deepEqual(view.render(), [" codemode return 1;", "", "  ✓ read file"]);
  view.click(0);
  assert.deepEqual(view.render(), [
    " codemode",
    "",
    "  ✓ read file",
    "",
    "   code return 1;",
    "",
    "   output hello",
  ]);
  assert.equal(formats, 0);
  // Tool status rows toggle the whole row.
  view.click(2);
  assert.equal(view.render().length, 3);
  view.click(0);
  view.click(4);
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(formats, 1);
  assert.deepEqual(view.render().slice(4), [
    "   code",
    "",
    "    return 1;",
    "",
    "   output hello",
  ]);
});

test("nested codemode tool previews match top-level rules even with truncated JSON", () => {
  const extra = "SECRET_METADATA".repeat(40);
  const cases = [
    ["bash", { command: "echo hello\necho world", timeout: 10, extra }],
    ["read", { path: "read.ext", offset: 1, limit: 20, extra }],
    ["write", { path: "write.ext", content: extra }],
    ["edit", { path: "edit.ext", edits: [{ oldText: extra, newText: "new" }] }],
    ["codemode", { code: 'return "hello";', extra }],
    ["other", { query: "hello", limit: 7 }],
  ];
  const truncated = (args) => {
    const source = JSON.stringify(args);
    return source.length > 200 ? source.slice(0, 197) + "..." : source;
  };
  for (const truncate of [false, true]) {
    const view = row("codemode", { code: "return;" });
    view.result(
      result("", {
        calls: cases.map(([name, args], i) => ({
          id: String(i),
          name,
          args: truncate ? truncated(args) : JSON.stringify(args),
          status: "ok",
        })),
      }),
    );
    for (const expanded of [false, true]) {
      view.expand(expanded);
      for (const [name, args] of cases) {
        const top = row(name, args);
        const expected = top.render(500)[0].replace(/^[] \S+\s*/, "");
        const nested = view.render(500).find((line) => line.trim().startsWith(`✓ ${name} `));
        assert.equal(nested.trim(), `✓ ${name} ${expected}`);
      }
      for (const width of [8, 20, 80]) {
        assert.ok(view.renderStyled(width).every((line) => tui.visibleWidth(line) <= width));
      }
    }
  }
});

test("truncated nested bash commands never fall back to unrelated argument JSON", () => {
  const source = JSON.stringify({
    timeout: 10,
    command: 'printf "hello";\n' + "界".repeat(250),
    extra: "SECRET_METADATA",
  });
  const view = row("codemode", { code: "return;" });
  view.result(
    result("", {
      calls: [
        { id: "1", name: "bash", args: source.slice(0, 197) + "...", status: "running" },
        { id: "2", name: "bash", args: '{"timeout":10,"extra":"SECRET_METADATA...', status: "ok" },
        { id: "3", name: "models.classify", args: "provider/model", status: "ok" },
      ],
    }),
  );
  for (const expanded of [false, true]) {
    view.expand(expanded);
    const lines = view.render(500);
    const command = lines.find((line) => line.trim().startsWith("… bash ")).trim();
    assert.ok(command.startsWith('… bash printf "hello"; 界'));
    assert.ok(command.endsWith("..."));
    assert.ok(
      !command.includes("timeout") &&
        !command.includes("command") &&
        !command.includes("SECRET_METADATA"),
    );
    assert.ok(lines.includes("  ✓ bash"));
    assert.ok(lines.includes("  ✓ models.classify provider/model"));
  }
});

test("streaming codemode waits for complete arguments before displaying formatted code", async () => {
  let formats = 0;
  const view = row(
    "codemode",
    { code: "return {a:1};" },
    {
      expanded: true,
      argsComplete: false,
      isPartial: true,
      formatter: async () => {
        formats++;
        return "return { a: 1 };";
      },
    },
  );
  assert.ok(view.render().includes("    Receiving code…"));
  assert.equal(formats, 0);
  view.context.argsComplete = true;
  view.context.invalidate();
  await new Promise((resolve) => setImmediate(resolve));
  assert.ok(view.render().includes("    return { a: 1 };"));
  assert.equal(formats, 1);
});

test("resumed codemode calls format even though argsComplete is not set by Pi", async () => {
  let formats = 0;
  const view = row(
    "codemode",
    { code: "return 1;" },
    {
      expanded: true,
      argsComplete: false,
      formatter: async () => {
        formats++;
        return "return 1;";
      },
    },
  );
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(formats, 1);
  assert.ok(view.render().includes("    return 1;"));
});

function subagentDetails(overrides = {}) {
  return {
    status: "running",
    output: "",
    model: "ai-gw-openai/openai/gpt-6-luna",
    thinking: "high",
    toolCalls: 2,
    durationMs: 3000,
    usage: { turns: 1, input: 1200, output: 340, cost: 0 },
    activity: [
      { kind: "tool", name: "read", preview: "file.ts", status: "ok" },
      { kind: "text", text: "Looking around" },
      { kind: "tool", name: "bash", preview: "git diff", status: "running" },
    ],
    ...overrides,
  };
}

const subagentArgs = {
  prompt: "Review the code\nin file.ts",
  model: "luna",
  thinking: "high",
  label: "Review",
};

test("subagent rows stream a status line and the latest tool calls while collapsed", () => {
  const view = row("subagent", subagentArgs);
  assert.deepEqual(view.render(), [" subagent Review · luna:high"]);
  view.result(result("(running…)", subagentDetails()), true);
  assert.deepEqual(view.render(), [
    " subagent Review · luna:high",
    "",
    "  … 1 turn · 2 tool calls · ↑1.2k ↓340 · 3s · gpt-6-luna:high",
    "    ✓ read file.ts",
    "    … bash git diff",
  ]);
  const activity = Array.from({ length: 7 }, (_, i) => ({
    kind: "tool",
    name: "read",
    preview: `f${i}`,
    status: "ok",
  }));
  view.result(
    result(
      "Subagent finished\n\nAll good",
      subagentDetails({ status: "done", output: "All good", toolCalls: 9, activity }),
    ),
  );
  assert.deepEqual(view.render().slice(2), [
    "  ✓ 1 turn · 9 tool calls · ↑1.2k ↓340 · 3s · gpt-6-luna:high",
    "    … 4 earlier tool calls",
    "    ✓ read f2",
    "    ✓ read f3",
    "    ✓ read f4",
    "    ✓ read f5",
    "    ✓ read f6",
  ]);
});

test("expanded subagent rows fold prompt, activity, and the bare answer", () => {
  const view = row("subagent", subagentArgs);
  const details = subagentDetails({
    status: "done",
    output: "All good\nNo issues",
    sessionFile: "/sessions/s.jsonl",
    activity: subagentDetails().activity.map((item) => ({ ...item, status: "ok" })),
  });
  view.result(result('Subagent "Review" finished\nSession: x\n\nAll good\nNo issues', details));
  view.click(0);
  assert.deepEqual(view.render(), [
    " subagent Review · luna:high",
    "",
    "  ✓ 1 turn · 2 tool calls · ↑1.2k ↓340 · 3s · gpt-6-luna:high",
    "  session /sessions/s.jsonl",
    "",
    "   prompt Review the code in file.ts",
    "",
    "   activity 2 tool calls",
    "",
    "   output All good No issues",
  ]);
  // Status rows toggle the whole row; section headers toggle only their section.
  view.click(2);
  assert.equal(view.render().length, 5); // collapsed: header, blank, status, two calls
  view.click(0);
  view.click(5);
  assert.deepEqual(view.render().slice(5), [
    "   prompt",
    "",
    "    Review the code",
    "    in file.ts",
    "",
    "   activity 2 tool calls",
    "",
    "   output All good No issues",
  ]);
  view.click(10);
  assert.deepEqual(view.render().slice(10), [
    "   activity",
    "",
    "    ✓ read file.ts",
    "    ✓ bash git diff",
    "",
    "   output All good No issues",
  ]);
  view.click(15);
  assert.deepEqual(view.render().slice(15), ["   output", "", "    All good", "    No issues"]);
});

test("failed subagents show the error in the header and output section", () => {
  const view = row("subagent", { prompt: "Do it" }, { isError: true });
  view.result(
    result(
      "Subagent failed",
      subagentDetails({
        status: "error",
        error: "Model not found",
        model: "nope",
        thinking: undefined,
        usage: {},
        toolCalls: 0,
        durationMs: 20,
        activity: [],
      }),
    ),
  );
  assert.deepEqual(view.render(), [" subagent Do it [error]", "", "  ✗ 0s · nope"]);
  view.click(0);
  assert.deepEqual(view.render().slice(3), [
    "",
    "   prompt Do it",
    "",
    "   output Model not found",
  ]);
});

test("subagent rows fall back to plain text output without subagent details", () => {
  const view = row("subagent", { prompt: "Do it", label: "Task" });
  view.result(result("plain answer"));
  view.click(0);
  assert.deepEqual(view.render(), [
    " subagent Task",
    "",
    "   prompt Do it",
    "",
    "   output plain answer",
  ]);
});

test("nested codemode subagent calls preview their label and model", () => {
  const view = row("codemode", { code: "return 1;" });
  const args = JSON.stringify({
    label: "Review",
    model: "luna",
    thinking: "high",
    prompt: "x".repeat(300),
  });
  view.result(
    result("", {
      calls: [{ id: "1", name: "subagent", args: args.slice(0, 200), status: "running" }],
    }),
    true,
  );
  assert.deepEqual(view.render().slice(1), ["", "  … subagent Review · luna:high"]);
});

test("unknown tools get input/output sections and errors remain visible", () => {
  const view = row("mcp__example__query", { query: "something" }, { isError: true });
  view.result(result("failed"));
  assert.ok(view.render()[0].includes("[error]"));
  view.expand(true);
  assert.ok(view.render().includes("   input"));
  assert.ok(view.render().includes("   output"));
  assert.ok(view.render().includes("    failed"));
});

test("write failures show the error, not the proposed content", () => {
  const view = row(
    "write",
    { path: "file", content: "not written" },
    { expanded: true, isError: true },
  );
  view.result(result("permission denied"));
  assert.deepEqual(view.render(), [" write file", "", "  permission denied"]);
});

test("renderer strips terminal control sequences from tool output", () => {
  const view = row("read", { path: "file" }, { expanded: true });
  view.result(result("\x1b[31mred\x1b[0m\x00\x07\r\nnext"));
  assert.deepEqual(view.render(), [" read file", "", "  red", "  next"]);
});

test("oxfmt formats an async body, and falls back for invalid input or a missing executable", async () => {
  const code = "const x={a:1};return await Promise.resolve(x);";
  const formatted = await formatCode(code, process.cwd());
  // oxfmt is optional, so only require formatting when the executable is installed.
  let available = false;
  try {
    execFileSync("oxfmt", ["--version"], { stdio: "ignore" });
    available = true;
  } catch {}
  assert.equal(
    formatted,
    available ? "const x = { a: 1 };\nreturn await Promise.resolve(x);" : code,
  );
  assert.equal(await formatCode("const = broken", process.cwd()), "const = broken");
  const savedPath = process.env.PATH;
  try {
    process.env.PATH = "/nonexistent";
    assert.equal(await formatCode(code, process.cwd()), code);
  } finally {
    process.env.PATH = savedPath;
  }
});

test("Pi's real extension loader and tool component preserve layouts and click expansion", async () => {
  const { loadExtensions } = await import(
    pathToFileURL(path.join(root, "dist/core/extensions/loader.js"))
  );
  const loaded = await loadExtensions([extensionPath], process.cwd());
  assert.deepEqual(loaded.errors, []);
  assert.equal(loaded.extensions.length, 1);
  const resolver = loaded.extensions[0].toolRenderers[0];
  const { initTheme } = await import(
    pathToFileURL(path.join(root, "dist/modes/interactive/theme/theme.js"))
  );
  initTheme("dark", false);
  const { ToolExecutionComponent } = await import(
    pathToFileURL(path.join(root, "dist/modes/interactive/components/tool-execution.js"))
  );
  const component = new ToolExecutionComponent(
    "edit",
    "integration",
    { path: "file.ext" },
    { outputPad: 1 },
    resolver("edit"),
    { requestRender() {} },
    process.cwd(),
  );
  component.updateResult(result("Applied", { diff: "-old\n+new" }));
  const plain = () =>
    component.render(40).map((line) => tui.stripTerminalSequences(line).trimEnd());
  assert.deepEqual(plain(), ["", "  edit file.ext", "", "   -old", "   +new"]);
  component.handleMouse({ type: "click", button: "left", x: 1, y: 1, width: 40, height: 5 });
  assert.deepEqual(plain(), ["", "  edit file.ext"]);
  component.setExpanded(true);
  assert.equal(plain()[1], "  edit file.ext");

  const bash = new ToolExecutionComponent(
    "bash",
    "integration-bash",
    { command: "echo hi" },
    { outputPad: 1 },
    resolver("bash"),
    { requestRender() {} },
    process.cwd(),
  );
  bash.updateResult(result("hi"));
  const bashPlain = () => bash.render(40).map((line) => tui.stripTerminalSequences(line).trimEnd());
  const click = (y) =>
    bash.handleMouse({ type: "click", button: "left", x: 1, y, width: 40, height: 9 });
  assert.deepEqual(bashPlain(), ["", "  bash echo hi"]);
  click(1);
  assert.deepEqual(bashPlain(), ["", "  bash", "", "    command echo hi", "", "    output hi"]);
  click(5);
  assert.deepEqual(bashPlain().slice(5), ["    output", "", "     hi"]);
  click(3);
  assert.deepEqual(bashPlain().slice(3, 6), ["    command", "", "     echo hi"]);
});

function assistant(content) {
  return { role: "assistant", content, stopReason: "stop" };
}

const assistantLines = (component, width = 40) => component.render(width);
const assistantPlain = (component, width = 40) =>
  assistantLines(component, width).map((line) => tui.stripTerminalSequences(line).trimEnd());

test("assistant prose gets a theme background and exactly one padding row on each side", () => {
  const dispose = installAssistantPanels(() => themeModule.theme);
  try {
    const component = new AssistantMessageComponent(
      assistant([{ type: "text", text: "Hello **world**" }]),
    );
    const lines = assistantLines(component);
    assert.deepEqual(assistantPlain(component), ["", "", " Hello world", ""]);
    // Native inter-message spacing stays outside the panel.
    assert.ok(!lines[0].includes(themeModule.theme.getBgAnsi("customMessageBg")));
    assert.ok(
      lines.slice(1).every((line) => line.includes(themeModule.theme.getBgAnsi("customMessageBg"))),
    );
    assert.ok(lines.slice(1).every((line) => tui.visibleWidth(line) === 40));
    assert.ok(lines[2].includes(themeModule.theme.bold("world")));
    for (const width of [4, 12, 40]) {
      assert.ok(assistantLines(component, width).every((line) => tui.visibleWidth(line) <= width));
    }
  } finally {
    dispose();
  }
});

test("assistant panels leave thinking and tool-only messages unshaded", () => {
  const dispose = installAssistantPanels(() => themeModule.theme);
  try {
    for (const hidden of [false, true]) {
      const component = new AssistantMessageComponent(
        assistant([
          { type: "thinking", thinking: "private reasoning" },
          { type: "text", text: "Public answer" },
        ]),
        hidden,
      );
      const lines = assistantLines(component);
      const shaded = lines.filter((line) =>
        line.includes(themeModule.theme.getBgAnsi("customMessageBg")),
      );
      assert.equal(shaded.length, 3);
      const thinking = lines.find((line) =>
        tui.stripTerminalSequences(line).includes(hidden ? "Thinking..." : "private reasoning"),
      );
      assert.ok(thinking);
      assert.ok(!thinking.includes(themeModule.theme.getBgAnsi("customMessageBg")));
    }
    const toolsOnly = new AssistantMessageComponent(
      assistant([{ type: "toolCall", id: "call", name: "read", arguments: { path: "file" } }]),
    );
    assert.deepEqual(assistantLines(toolsOnly), []);
  } finally {
    dispose();
  }
});

test("assistant streaming updates and repeated invalidation do not accumulate padding", () => {
  const dispose = installAssistantPanels(() => themeModule.theme);
  try {
    const component = new AssistantMessageComponent();
    const message = assistant([
      { type: "text", text: "First" },
      { type: "text", text: "Second" },
    ]);
    const before = structuredClone(message);
    for (let i = 0; i < 3; i++) {
      component.updateContent(message, true);
      component.invalidate();
      assert.deepEqual(assistantPlain(component), ["", "", " First", " Second", ""]);
    }
    assert.deepEqual(message, before);
    component.updateContent(assistant([{ type: "text", text: "Done" }]), false);
    assert.deepEqual(assistantPlain(component), ["", "", " Done", ""]);
  } finally {
    dispose();
  }
});

test("assistant panel backgrounds follow theme changes and unload cleanly without stacking", () => {
  const native = AssistantMessageComponent.prototype.updateContent;
  const disposeFirst = installAssistantPanels(() => themeModule.theme);
  const component = new AssistantMessageComponent(assistant([{ type: "text", text: "Answer" }]));
  const dark = assistantLines(component).join("\n");
  let disposeSecond;
  try {
    themeModule.initTheme("light", false);
    component.invalidate();
    const light = assistantLines(component).join("\n");
    assert.ok(light.includes(themeModule.theme.getBgAnsi("customMessageBg")));
    assert.notEqual(light, dark);
    disposeSecond = installAssistantPanels(() => themeModule.theme);
    disposeFirst(); // Old runtime cleanup must not remove the newer patch.
    component.updateContent(assistant([{ type: "text", text: "Reloaded" }]));
    assert.deepEqual(assistantPlain(component), ["", "", " Reloaded", ""]);
    disposeSecond();
    disposeSecond();
    assert.equal(AssistantMessageComponent.prototype.updateContent, native);
    assert.deepEqual(assistantPlain(component), ["", " Reloaded"]);
    assert.ok(
      !assistantLines(component)
        .join("\n")
        .includes(themeModule.theme.getBgAnsi("customMessageBg")),
    );
  } finally {
    disposeFirst();
    disposeSecond?.();
    themeModule.initTheme("dark", false);
  }
});

test("assistant decoration is installed only in TUI sessions and removed on shutdown", () => {
  const handlers = new Map();
  extension({
    registerToolRenderer() {},
    on(name, handler) {
      handlers.set(name, handler);
    },
  });
  const native = AssistantMessageComponent.prototype.updateContent;
  try {
    handlers.get("session_start")({}, { mode: "print" });
    assert.equal(AssistantMessageComponent.prototype.updateContent, native);
    handlers.get("session_start")(
      {},
      {
        mode: "tui",
        ui: {
          get theme() {
            return themeModule.theme;
          },
        },
      },
    );
    assert.notEqual(AssistantMessageComponent.prototype.updateContent, native);
    handlers.get("session_shutdown")();
    assert.equal(AssistantMessageComponent.prototype.updateContent, native);
  } finally {
    handlers.get("session_shutdown")();
  }
});

test("extension registers a renderer resolver without replacing any tool execution", () => {
  let resolver;
  extension({
    registerToolRenderer(value) {
      resolver = value;
    },
    on() {},
  });
  assert.equal(resolver("read").renderShell, "self");
  assert.equal(resolver("codemode").renderShell, "self");
  assert.equal(resolver("future_mcp_tool").renderShell, "self");
  assert.equal(resolver("subagent").renderShell, "self");
});
