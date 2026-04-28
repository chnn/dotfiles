/**
 * Terminal Title Extension
 *
 * Keeps the terminal title set to "<repo_name_or_folder> | pi" while pi is running.
 *
 * - Uses the git repository's top-level folder name when inside a git repo.
 * - Falls back to the basename of the current working directory otherwise.
 * - Refreshes on session start, after each turn, and on shutdown (clears).
 */

import { execSync } from "node:child_process";
import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

function getRepoOrFolderName(cwd: string): string {
	try {
		const top = execSync("git rev-parse --show-toplevel", {
			cwd,
			stdio: ["ignore", "pipe", "ignore"],
			encoding: "utf8",
		}).trim();
		if (top) return path.basename(top);
	} catch {
		// not a git repo, or git not available
	}
	return path.basename(cwd) || cwd;
}

function buildTitle(cwd: string): string {
	return `${getRepoOrFolderName(cwd)} | pi`;
}

// OSC 0 sets both the window and icon title. Writing directly to the TTY
// lets us paint the title before pi finishes booting and before any
// extension event fires.
function writeTitleDirect(title: string): void {
	try {
		if (process.stdout.isTTY) {
			process.stdout.write(`\x1b]0;${title}\x07`);
		}
	} catch {
		// ignore — title is best-effort
	}
}

export default function (pi: ExtensionAPI) {
	let cachedTitle: string | null = null;

	// Paint the title immediately at extension load time, before any session
	// events fire. This covers the brief startup window where pi (or its
	// children) may otherwise leave a stale shell title in place.
	{
		const title = buildTitle(process.cwd());
		cachedTitle = title;
		writeTitleDirect(title);
	}

	function applyTitle(ctx: ExtensionContext) {
		const title = buildTitle(ctx.cwd ?? process.cwd());
		cachedTitle = title;
		ctx.ui.setTitle(title);
	}

	// Set on startup / new / resume / fork / reload.
	pi.on("session_start", async (_event, ctx) => {
		applyTitle(ctx);
	});

	// Re-assert after each turn in case something else (a tool, another
	// extension, a child process) changed the title.
	pi.on("turn_end", async (_event, ctx) => {
		applyTitle(ctx);
	});

	pi.on("agent_end", async (_event, ctx) => {
		applyTitle(ctx);
	});

	// Clear the custom title on shutdown so the user's shell can take over.
	pi.on("session_shutdown", async (_event, ctx) => {
		cachedTitle = null;
		ctx.ui.setTitle("");
		writeTitleDirect("");
	});

	// Silence "unused" if cachedTitle ever becomes purely informational.
	void cachedTitle;
}
