/**
 * macOS Notify Extension
 *
 * Sends a native macOS notification when the current agent turn completes,
 * unless the terminal is currently focused.
 *
 * Use `/notify` to toggle notifications on/off for the current session.
 */

import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const execFileAsync = promisify(execFile);

// Map TERM_PROGRAM env values to macOS app process names returned by
// `System Events`. Extend as needed.
const TERM_PROGRAM_TO_APP: Record<string, string[]> = {
	ghostty: ["ghostty", "Ghostty"],
	"iTerm.app": ["iTerm2", "iTerm"],
	Apple_Terminal: ["Terminal"],
	WezTerm: ["WezTerm", "wezterm-gui"],
	alacritty: ["Alacritty", "alacritty"],
	kitty: ["kitty"],
	tabby: ["Tabby"],
	WarpTerminal: ["Warp"],
	vscode: ["Code", "Code - Insiders", "Cursor"],
	Hyper: ["Hyper"],
};

function getTerminalAppNames(): string[] {
	const term = process.env.TERM_PROGRAM ?? "";
	const mapped = TERM_PROGRAM_TO_APP[term];
	if (mapped) return mapped;
	// Fall back to the raw TERM_PROGRAM value if we have no mapping.
	return term ? [term] : [];
}

async function isTerminalFocused(): Promise<boolean> {
	const candidates = getTerminalAppNames();
	if (candidates.length === 0) return false;
	try {
		const { stdout } = await execFileAsync(
			"osascript",
			[
				"-e",
				'tell application "System Events" to get name of first application process whose frontmost is true',
			],
			{ timeout: 1500 },
		);
		const frontmost = stdout.trim();
		return candidates.some((name) => name.toLowerCase() === frontmost.toLowerCase());
	} catch {
		// If we can't determine focus (e.g. permissions denied), err on the side
		// of notifying so the user isn't silently missing turn completions.
		return false;
	}
}

function escapeForAppleScript(value: string): string {
	return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

async function sendMacNotification(title: string, body: string): Promise<void> {
	const script = `display notification "${escapeForAppleScript(body)}" with title "${escapeForAppleScript(title)}" sound name "Pop"`;
	try {
		await execFileAsync("osascript", ["-e", script], { timeout: 3000 });
	} catch {
		// Swallow errors — notifications are best-effort.
	}
}

export default function (pi: ExtensionAPI) {
	// Per-session toggle state. Defaults to enabled.
	let enabled = true;

	pi.on("agent_end", async () => {
		if (!enabled) return;
		if (process.platform !== "darwin") return;
		if (await isTerminalFocused()) return;
		await sendMacNotification("pi", "Agent turn complete");
	});

	pi.registerCommand("notify", {
		description: "Toggle macOS turn-complete notifications for this session",
		getArgumentCompletions: (prefix: string) => {
			const items = [
				{ value: "on", label: "on" },
				{ value: "off", label: "off" },
				{ value: "toggle", label: "toggle" },
				{ value: "status", label: "status" },
				{ value: "test", label: "test" },
			];
			const filtered = items.filter((i) => i.value.startsWith(prefix));
			return filtered.length > 0 ? filtered : null;
		},
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim().toLowerCase();

			if (arg === "status") {
				ctx.ui.notify(
					`macOS notifications are ${enabled ? "ON" : "OFF"} for this session`,
					"info",
				);
				return;
			}

			if (arg === "test") {
				if (process.platform !== "darwin") {
					ctx.ui.notify("Not running on macOS — skipping test", "warning");
					return;
				}
				await sendMacNotification("pi", "Test notification");
				ctx.ui.notify("Sent test notification", "info");
				return;
			}

			if (arg === "on") {
				enabled = true;
			} else if (arg === "off") {
				enabled = false;
			} else {
				// Default action (no arg or "toggle") flips the current state.
				enabled = !enabled;
			}

			ctx.ui.notify(
				`macOS notifications ${enabled ? "enabled" : "disabled"} for this session`,
				"info",
			);
		},
	});
}
