// Run: node --test .config/television/scripts/pi-sessions.test.mjs
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, realpathSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { after, test } from "node:test";
import { fileURLToPath } from "node:url";

const helper = fileURLToPath(new URL("./pi-sessions.mjs", import.meta.url));
const shell = resolve(dirname(helper), "../../zsh/pi.zsh");
const root = realpathSync(mkdtempSync(join(tmpdir(), "pi-picker-test-")));
after(() => rmSync(root, { recursive: true, force: true }));
const agent = join(root, "agent");
const project = join(root, "project with 'quotes', $dollars, tabs\tand\nnewlines");
const config = join(root, "config");
const bin = join(root, "bin");
for (const dir of [agent, project, bin, join(config, "television", "scripts")]) mkdirSync(dir, { recursive: true });
symlinkSync(helper, join(config, "television", "scripts", "pi-sessions.mjs"));

function session(file, cwd, entries, seconds) {
  mkdirSync(dirname(file), { recursive: true });
  const header = { type: "session", version: 3, id: "abc12345-full-id", cwd };
  writeFileSync(file, [header, ...entries].map((entry) => JSON.stringify(entry)).join("\n") + "\n");
  utimesSync(file, seconds, seconds);
  return file;
}
const older = session(join(agent, "sessions", "--project-a--", "older.jsonl"), root,
  [{ type: "message", message: { role: "user", content: "Old prompt" } }], 1700000000);
const newer = session(join(agent, "sessions", "--project-b--", "new 'quoted'\nfile.jsonl"), project,
  [{ type: "message", message: { role: "user", content: [{ type: "image" }, { type: "text", text: "First\nprompt" }] } },
    { type: "session_info", name: "Old name" }, { type: "session_info", name: "Newest\tname\u001b" }], 1700000100);
writeFileSync(join(agent, "sessions", "invalid.jsonl"), "not json\n");
session(join(agent, "sessions", "relative-cwd.jsonl"), "relative", [], 1700000200);

const env = { ...process.env, PI_CODING_AGENT_DIR: agent, PI_CODING_AGENT_SESSION_DIR: "", XDG_CONFIG_HOME: config };
const run = (...args) => spawnSync(process.execPath, [helper, ...args], { env, encoding: "utf8" });
const token = (file) => Buffer.from(file).toString("base64url");

test("lists all projects newest first with sanitized directories and latest session names", () => {
  const result = run("list");
  assert.equal(result.status, 0, result.stderr);
  const rows = result.stdout.trim().split("\n").map((line) => line.split("\t"));
  assert.equal(rows.length, 2);
  assert.equal(rows[0][0], token(newer));
  assert.match(rows[0][1], /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/);
  assert.equal(rows[0][2], project.replace(/[\t\n]/g, " "));
  assert.equal(rows[0][3], "Newest name");
  assert.equal(rows[0][4], "abc12345");
  assert.equal(rows[1][0], token(older));
  assert.equal(rows[1][3], "Old prompt");
});

test("includes custom storage, name clears, empty sessions, and incomplete live entries", () => {
  const custom = join(root, "custom");
  const file = session(join(custom, "live.jsonl"), project,
    [{ type: "message", message: { role: "user", content: [{ type: "text", text: "Fallback\nprompt" }] } },
      { type: "session_info", name: "Cleared name" }, { type: "session_info" }], 1700000300);
  writeFileSync(file, '{"type":"message"', { flag: "a" });
  session(join(custom, "empty.jsonl"), root, [], 1700000250);
  writeFileSync(join(agent, "settings.json"), JSON.stringify({ sessionDir: custom }));
  try {
    const result = spawnSync(process.execPath, [helper, "list"], {
      env: { ...env, PI_CODING_AGENT_SESSION_DIR: custom }, encoding: "utf8",
    });
    assert.equal(result.status, 0, result.stderr);
    const rows = result.stdout.trim().split("\n").map((line) => line.split("\t"));
    assert.equal(rows.length, 4); // Custom directory is not listed twice.
    assert.equal(rows[0][3], "Fallback prompt");
    assert.equal(rows[1][3], "(no messages)");
  } finally {
    rmSync(join(agent, "settings.json"));
  }
});

test("resolves paths losslessly and rejects invalid or deleted selections", () => {
  const result = run("resolve", token(newer));
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, project + "\0" + newer + "\0");
  assert.equal(run("resolve", "$(touch bad)").status, 1);
  assert.equal(run("resolve", token(join(root, "deleted.jsonl"))).status, 1);
});

writeFileSync(join(bin, "tv"), '#!/bin/sh\n[ "$TV_EXIT" = 0 ] || exit "$TV_EXIT"\nprintf "%s\\n" "$TV_SELECTION"\n', { mode: 0o755 });
writeFileSync(join(bin, "pi"), '#!/usr/bin/env node\nconsole.log(JSON.stringify({cwd:process.cwd(),args:process.argv.slice(2)}));\nprocess.exit(Number(process.env.PI_EXIT || 0));\n', { mode: 0o755 });
function picker(selection, tvExit = 0, piExit = 0) {
  return spawnSync("zsh", ["-f", "-c", 'source "$PIR_SOURCE"; pir --model "some model"; code=$?; node -e "console.log(JSON.stringify(process.cwd()))"; exit $code'], {
    cwd: root,
    env: { ...env, PATH: bin + ":" + env.PATH, PIR_SOURCE: shell, TV_SELECTION: selection, TV_EXIT: String(tvExit), PI_EXIT: String(piExit) },
    encoding: "utf8",
  });
}

test("pir changes the calling shell directory and resumes the exact file, forwarding Pi options", () => {
  const result = picker(token(newer));
  assert.equal(result.status, 0, result.stderr);
  const [invocation, cwd] = result.stdout.trim().split("\n").map(JSON.parse);
  assert.deepEqual(invocation, { cwd: project, args: ["--session", newer, "--model", "some model"] });
  assert.equal(cwd, project);
  assert.equal(picker(token(newer), 0, 7).status, 7);
});

test("cancelling, an empty selection, or a missing project never launches Pi or changes directory", () => {
  for (const [selection, tvExit, expected] of [[token(newer), 130, 130], ["", 0, 0]]) {
    const result = picker(selection, tvExit);
    assert.equal(result.status, expected, result.stderr);
    assert.equal(JSON.parse(result.stdout), root);
  }
  const file = session(join(root, "missing-project.jsonl"), join(root, "removed-project"), [], 1700000000);
  const result = picker(token(file));
  assert.equal(result.status, 1);
  assert.match(result.stderr, /session directory no longer exists/);
  assert.equal(JSON.parse(result.stdout), root);
});

test("no session storage yet produces an empty list", () => {
  const result = spawnSync(process.execPath, [helper, "list"], {
    env: { ...env, PI_CODING_AGENT_DIR: join(root, "no-agent-yet") }, encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, "");
});
