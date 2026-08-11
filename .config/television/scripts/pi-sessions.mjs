#!/usr/bin/env node
// Television source for Pi sessions. Rows carry an opaque path token so shell
// metacharacters, tabs, and newlines in paths never become shell commands.
import { readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

const expandPath = (path) => resolve(path === "~" ? homedir() : path.replace(/^~\//, homedir() + "/"));
const agentDir = expandPath(process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi", "agent"));
const clean = (value) => String(value ?? "").replace(/[\x00-\x1f\x7f-\x9f]/g, " ").replace(/\s+/g, " ").trim();

function sessionFiles(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
  return entries.flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return sessionFiles(path);
    return entry.isFile() && entry.name.endsWith(".jsonl") ? [path] : [];
  });
}

function readHeader(file) {
  const text = readFileSync(file, "utf8");
  const header = JSON.parse(text.split("\n", 1)[0]);
  if (header.type !== "session" || typeof header.cwd !== "string" || !isAbsolute(header.cwd) || header.cwd.includes("\0")) {
    throw new Error("Session has no valid working directory: " + file);
  }
  return { header, text };
}

function list() {
  const roots = new Set([join(agentDir, "sessions")]);
  // Include custom storage alongside the default history, across all projects.
  if (process.env.PI_CODING_AGENT_SESSION_DIR) roots.add(expandPath(process.env.PI_CODING_AGENT_SESSION_DIR));
  try {
    const settings = JSON.parse(readFileSync(join(agentDir, "settings.json"), "utf8"));
    if (typeof settings.sessionDir === "string" && settings.sessionDir) roots.add(expandPath(settings.sessionDir));
  } catch (error) {
    if (error.code !== "ENOENT" && !(error instanceof SyntaxError)) throw error;
  }

  const sessions = [];
  for (const file of new Set([...roots].flatMap(sessionFiles))) {
    try {
      const { header, text } = readHeader(file);
      let name;
      let firstMessage = "";
      for (const line of text.split("\n").slice(1)) {
        // Avoid parsing the large assistant/tool entries just to get a title.
        if (!line.includes('"session_info"') && !line.includes('"user"')) continue;
        let entry;
        try { entry = JSON.parse(line); } catch { continue; } // A live session may have an incomplete final line.
        if (entry?.type === "session_info") name = entry.name;
        if (!firstMessage && entry?.type === "message" && entry.message?.role === "user") {
          const content = entry.message.content;
          firstMessage = typeof content === "string" ? content : Array.isArray(content)
            ? content.filter((block) => block?.type === "text").map((block) => block.text).join(" ") : "";
        }
      }
      sessions.push({ file, cwd: header.cwd, id: header.id, title: clean(name) || clean(firstMessage) || "(no messages)", modified: statSync(file).mtimeMs });
    } catch {
      // Ignore malformed, unreadable, or concurrently deleted session files.
    }
  }
  sessions.sort((a, b) => b.modified - a.modified || a.file.localeCompare(b.file));
  for (const session of sessions) {
    const date = new Date(session.modified).toLocaleString("sv-SE", { hour12: false }).slice(0, 16);
    const cwd = session.cwd === homedir() ? "~" : session.cwd.startsWith(homedir() + "/") ? "~" + session.cwd.slice(homedir().length) : session.cwd;
    const token = Buffer.from(session.file).toString("base64url");
    console.log([token, date, clean(cwd), session.title.slice(0, 160), clean(session.id).slice(0, 8)].join("\t"));
  }
}

try {
  if (process.argv[2] === "list") {
    list();
  } else if (process.argv[2] === "resolve" && /^[A-Za-z0-9_-]+$/.test(process.argv[3] || "")) {
    const file = Buffer.from(process.argv[3], "base64url").toString("utf8");
    if (!isAbsolute(file) || file.includes("\0")) throw new Error("Invalid session path");
    const { header } = readHeader(file);
    // NUL separators preserve even newlines in paths; the zsh function uses read -d ''.
    process.stdout.write(header.cwd + "\0" + file + "\0");
  } else {
    throw new Error("Usage: pi-sessions.mjs list | resolve <session-token>");
  }
} catch (error) {
  console.error("pi-sessions: " + error.message);
  process.exitCode = 1;
}
