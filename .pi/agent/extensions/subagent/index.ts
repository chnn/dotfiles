/**
 * Subagent Extension
 *
 * Registers a `subagent` tool that runs a self-contained prompt in a brand-new
 * pi session (separate process, fresh context) and returns the subagent's final
 * answer to the calling session.
 *
 *   "use an astra high subagent to audit the auth module"
 *     -> subagent({ model: "astra", thinking: "high", label: "audit auth", prompt: "..." })
 *
 * Parallel: issue several tool calls in one turn, or from codemode:
 *   await Promise.all([tools.subagent({...}), tools.subagent({...})])
 *
 * Subagent sessions are persisted to ~/.pi/agent/subagent-sessions so they can be
 * inspected or continued later with `pi --session <file>`.
 *
 * Env:
 *   PI_SUBAGENT_MAX_DEPTH    max nesting depth (default 1: subagents can't spawn subagents)
 *   PI_SUBAGENT_CONCURRENCY  max subagents running at once per pi process (default 6)
 */

import { spawn, type ChildProcess } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import type { Usage } from "@earendil-works/pi-ai";
import { type ExtensionAPI, getAgentDir, getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const DEPTH = Number(process.env.PI_SUBAGENT_DEPTH ?? "0") || 0;
const MAX_DEPTH = Number(process.env.PI_SUBAGENT_MAX_DEPTH ?? "1") || 1;
const CONCURRENCY = Math.max(1, Number(process.env.PI_SUBAGENT_CONCURRENCY ?? "6") || 6);
const OUTPUT_CAP = 50 * 1024;
const MAX_ACTIVITY = 40;
const COLLAPSED_ACTIVITY = 6;

const THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

const SUBAGENT_SYSTEM_NOTE = `You are running as a subagent: a separate pi session started by another agent to complete one delegated task.
- You have a fresh context. Everything you know about the task is in the user's prompt; gather anything else yourself with your tools.
- Nobody can answer questions mid-task. If something is ambiguous, make a reasonable assumption, state it, and continue.
- Your final message is returned verbatim to the calling agent as the task result. Make it complete and self-contained: lead with the answer/outcome, include concrete details (file paths, line numbers, commands, findings), and list anything you changed or could not finish. Do not refer to earlier messages the caller cannot see.`;

// ---------------------------------------------------------------------------
// Types

type Status = "running" | "done" | "error" | "aborted";

type ToolStatus = "running" | "ok" | "error" | "cancelled";

/** `preview` is the argument summary without the tool name, e.g. the command for bash. */
type Activity =
	| { kind: "tool"; id?: string; name: string; preview: string; status: ToolStatus }
	| { kind: "text"; text: string };

interface SubagentUsage {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	totalTokens: number;
	cost: number;
	turns: number;
	contextTokens: number;
}

interface SubagentDetails {
	label: string;
	prompt: string;
	requestedModel?: string;
	thinking?: string;
	model?: string;
	cwd: string;
	status: Status;
	output: string;
	error?: string;
	stopReason?: string;
	sessionFile?: string;
	activity: Activity[];
	toolCalls: number;
	usage: SubagentUsage;
	startedAt: number;
	durationMs: number;
}

// ---------------------------------------------------------------------------
// Helpers

function emptyUsage(): SubagentUsage {
	return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: 0, turns: 0, contextTokens: 0 };
}

function toPiUsage(u: SubagentUsage): Usage {
	return {
		input: u.input,
		output: u.output,
		cacheRead: u.cacheRead,
		cacheWrite: u.cacheWrite,
		totalTokens: u.totalTokens,
		cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: u.cost },
	};
}

function shortenPath(p: string): string {
	const home = os.homedir();
	return p.startsWith(home) ? `~${p.slice(home.length)}` : p;
}

function oneLine(s: string, max: number): string {
	const flat = s.replace(/\s+/g, " ").trim();
	return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

function toolPreview(name: string, args: Record<string, unknown> | undefined): string {
	const a = args ?? {};
	const p = (a.path ?? a.file_path) as string | undefined;
	switch (name) {
		case "bash":
			return oneLine(String(a.command ?? ""), 200);
		case "read":
		case "write":
		case "edit":
		case "ls":
			return p ? shortenPath(p) : "";
		case "grep":
		case "find":
			return `${oneLine(String(a.pattern ?? ""), 80)}${p ? ` in ${shortenPath(p)}` : ""}`;
		case "codemode":
			return oneLine(String(a.code ?? ""), 200);
		default:
			return oneLine(
				Object.entries(a)
					.map(([k, v]) => `${k}=${typeof v === "string" ? v : JSON.stringify(v)}`)
					.join(" "),
				200,
			);
	}
}

function formatTokens(n: number): string {
	if (n < 1000) return String(n);
	if (n < 10_000) return `${(n / 1000).toFixed(1)}k`;
	if (n < 1_000_000) return `${Math.round(n / 1000)}k`;
	return `${(n / 1_000_000).toFixed(1)}M`;
}

function formatDuration(ms: number): string {
	const s = Math.round(ms / 1000);
	return s < 60 ? `${s}s` : `${Math.floor(s / 60)}m${String(s % 60).padStart(2, "0")}s`;
}

function formatStats(d: SubagentDetails): string {
	const u = d.usage;
	const parts: string[] = [];
	if (u.turns) parts.push(`${u.turns} turn${u.turns === 1 ? "" : "s"}`);
	if (d.toolCalls) parts.push(`${d.toolCalls} tool call${d.toolCalls === 1 ? "" : "s"}`);
	if (u.input) parts.push(`↑${formatTokens(u.input)}`);
	if (u.output) parts.push(`↓${formatTokens(u.output)}`);
	if (u.cacheRead) parts.push(`R${formatTokens(u.cacheRead)}`);
	if (u.cost) parts.push(`$${u.cost.toFixed(4)}`);
	if (u.contextTokens) parts.push(`ctx:${formatTokens(u.contextTokens)}`);
	parts.push(formatDuration(d.durationMs));
	if (d.model) parts.push(d.model + (d.thinking ? `:${d.thinking}` : ""));
	return parts.join(" · ");
}

function truncateOutput(s: string): string {
	const bytes = Buffer.byteLength(s, "utf8");
	if (bytes <= OUTPUT_CAP) return s;
	let cut = s.slice(0, OUTPUT_CAP);
	while (Buffer.byteLength(cut, "utf8") > OUTPUT_CAP) cut = cut.slice(0, -1);
	return `${cut}\n\n[Subagent output truncated: ${bytes - Buffer.byteLength(cut, "utf8")} bytes omitted.]`;
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const script = process.argv[1];
	if (script && !script.startsWith("/$bunfs/root/") && fs.existsSync(script)) {
		return { command: process.execPath, args: [script, ...args] };
	}
	const exec = path.basename(process.execPath).toLowerCase();
	if (!/^(node|bun)(\.exe)?$/.test(exec)) return { command: process.execPath, args };
	return { command: "pi", args };
}

function findSessionFile(dir: string, id: string | undefined): string | undefined {
	if (!id) return undefined;
	try {
		const match = fs.readdirSync(dir).find((f) => f.endsWith(`_${id}.jsonl`));
		return match ? path.join(dir, match) : undefined;
	} catch {
		return undefined;
	}
}

/** Simple FIFO semaphore shared by all subagent calls in this process. */
function createSemaphore(limit: number) {
	let active = 0;
	const queue: Array<() => void> = [];
	return async function acquire(signal?: AbortSignal): Promise<() => void> {
		if (active >= limit) {
			await new Promise<void>((resolve, reject) => {
				const go = () => {
					signal?.removeEventListener("abort", onAbort);
					resolve();
				};
				const onAbort = () => {
					const i = queue.indexOf(go);
					if (i >= 0) queue.splice(i, 1);
					reject(new Error("Subagent was aborted while queued"));
				};
				queue.push(go);
				signal?.addEventListener("abort", onAbort, { once: true });
			});
		}
		active++;
		let released = false;
		return () => {
			if (released) return;
			released = true;
			active--;
			queue.shift()?.();
		};
	};
}

// ---------------------------------------------------------------------------
// Schema

const Params = Type.Object({
	prompt: Type.String({
		description:
			"Complete, self-contained prompt for the subagent. It starts with zero context: include the goal, relevant background, file paths, constraints, and exactly what its final answer should contain.",
	}),
	model: Type.Optional(
		Type.String({
			description:
				'Model pattern, fuzzy-matched like `pi --model` (e.g. "astra", "opus", "provider/id"). Omit to use the current session\'s model.',
		}),
	),
	thinking: Type.Optional(
		StringEnum(THINKING_LEVELS, {
			description: "Thinking level for the subagent. Omit to inherit the current session's level.",
		}),
	),
	label: Type.Optional(Type.String({ description: "Short (2-5 word) name for the task, shown in the UI." })),
	cwd: Type.Optional(Type.String({ description: "Working directory for the subagent. Defaults to the current one." })),
	tools: Type.Optional(
		Type.String({
			description:
				'Optional comma-separated tool allowlist, as for `pi --tools` (e.g. "read,grep,find,ls" for read-only). Omit for the default tool set.',
		}),
	),
});

const OutputSchema = Type.Object({
	ok: Type.Boolean(),
	label: Type.String(),
	status: Type.String(),
	output: Type.String({ description: "The subagent's final answer" }),
	error: Type.Optional(Type.String()),
	model: Type.Optional(Type.String()),
	thinking: Type.Optional(Type.String()),
	sessionFile: Type.Optional(Type.String({ description: "Persisted subagent session; open with `pi --session <file>`" })),
	turns: Type.Number(),
	toolCalls: Type.Number(),
	cost: Type.Number(),
	durationMs: Type.Number(),
});

// ---------------------------------------------------------------------------
// Extension

export default function (pi: ExtensionAPI) {
	// Subagents don't get the tool (prevents runaway recursion) unless depth allows it.
	if (DEPTH >= MAX_DEPTH) return;

	const sessionDir = path.join(getAgentDir(), "subagent-sessions");
	const acquire = createSemaphore(CONCURRENCY);
	const children = new Set<ChildProcess>();

	pi.on("session_shutdown", () => {
		for (const child of children) child.kill("SIGTERM");
		children.clear();
	});

	pi.registerTool({
		name: "subagent",
		label: "Subagent",
		description: [
			"Run a task in a new, separate pi agent session with a fresh context (its own process, tools, and model), then return its final answer here.",
			"Use when the user asks for a subagent (e.g. 'use an astra high subagent to X' -> model: \"astra\", thinking: \"high\"), or to offload self-contained research/implementation work without filling this context.",
			"The subagent sees ONLY `prompt`: write it as a complete brief.",
			"For parallel subagents, issue multiple subagent calls in the same turn, or call tools.subagent() several times with Promise.all from codemode (structured result: { ok, output, error, sessionFile, ... }).",
		].join(" "),
		promptSnippet: "Delegate a self-contained task to a fresh-context subagent session (optionally on another model)",
		promptGuidelines: [
			'When the user says "use a <model> <level> subagent to X", call subagent with model "<model>" and thinking "<level>" (e.g. "astra high" -> model "astra", thinking "high"). Omit either to inherit the current session\'s.',
			"Before calling subagent, turn X into a self-contained prompt: the goal, why it matters, relevant context you already know (paths, findings, constraints, conventions), what to do and not do (e.g. read-only vs. edit files), and the exact shape of the final answer you want back. The subagent cannot see this conversation or ask questions.",
			"For several independent subagent tasks, run them in parallel (multiple subagent calls in one turn, or Promise.all over tools.subagent in codemode); give each a distinct label and avoid having parallel subagents edit the same files.",
			"Subagent results are reports from another agent: verify important claims before relying on them, and summarize the results for the user.",
		],
		parameters: Params,
		outputSchema: OutputSchema,
		executionMode: "parallel",

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const cwd = params.cwd ? path.resolve(ctx.cwd, params.cwd) : ctx.cwd;
			const label = params.label?.trim() || oneLine(params.prompt, 40);
			const parentModel = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
			const thinking = params.thinking ?? pi.getThinkingLevel();
			const modelArg = params.model?.trim() || parentModel;

			const details: SubagentDetails = {
				label,
				prompt: params.prompt,
				requestedModel: params.model,
				thinking,
				model: modelArg,
				cwd,
				status: "running",
				output: "",
				activity: [],
				toolCalls: 0,
				usage: emptyUsage(),
				startedAt: Date.now(),
				durationMs: 0,
			};

			const snapshot = (): SubagentDetails => ({
				...details,
				activity: details.activity.map((a) => ({ ...a })),
				usage: { ...details.usage },
				durationMs: Date.now() - details.startedAt,
			});
			const emit = () =>
				onUpdate?.({
					content: [{ type: "text", text: details.output || `(subagent "${label}" running…)` }],
					details: snapshot(),
				});
			const pushActivity = (a: Activity) => {
				details.activity.push(a);
				if (details.activity.length > MAX_ACTIVITY) details.activity.splice(0, details.activity.length - MAX_ACTIVITY);
			};

			const finish = () => {
				details.durationMs = Date.now() - details.startedAt;
				// The child has exited: anything still marked running never finished.
				for (const a of details.activity) if (a.kind === "tool" && a.status === "running") a.status = "cancelled";
				const ok = details.status === "done";
				const structured = {
					ok,
					label,
					status: details.status,
					output: details.output,
					...(details.error ? { error: details.error } : {}),
					...(details.model ? { model: details.model } : {}),
					...(details.thinking ? { thinking: details.thinking } : {}),
					...(details.sessionFile ? { sessionFile: details.sessionFile } : {}),
					turns: details.usage.turns,
					toolCalls: details.toolCalls,
					cost: details.usage.cost,
					durationMs: details.durationMs,
				};
				const header = `Subagent "${label}" ${ok ? "finished" : details.status}${details.model ? ` (${details.model}${details.thinking ? `:${details.thinking}` : ""})` : ""}${details.sessionFile ? `\nSession: ${details.sessionFile}` : ""}`;
				const body = ok
					? truncateOutput(details.output || "(no output)")
					: `Error: ${details.error ?? "unknown error"}${details.output ? `\n\nLast output:\n${truncateOutput(details.output)}` : ""}`;
				return {
					content: [{ type: "text" as const, text: `${header}\n\n${body}` }],
					details: snapshot(),
					structuredContent: structured,
					usage: toPiUsage(details.usage),
					...(ok ? {} : { isError: true }),
				};
			};

			let release: (() => void) | undefined;
			try {
				emit();
				release = await acquire(signal);
				details.startedAt = Date.now();

				fs.mkdirSync(sessionDir, { recursive: true });
				// Long text args break pi's CLI (it stats message/append args as paths; ENAMETOOLONG near
				// PATH_MAX makes it exit 1 silently). So: system note goes via a file, prompt via stdin.
				const notePath = path.join(sessionDir, ".subagent-system-note.md");
				if (!fs.existsSync(notePath) || fs.readFileSync(notePath, "utf8") !== SUBAGENT_SYSTEM_NOTE) {
					fs.writeFileSync(notePath, SUBAGENT_SYSTEM_NOTE);
				}
				const args = ["--mode", "json", "-p", "--session-dir", sessionDir, "--name", `subagent: ${oneLine(label, 80)}`];
				if (modelArg) args.push("--model", modelArg);
				if (thinking) args.push("--thinking", thinking);
				if (params.tools?.trim()) args.push("--tools", params.tools.trim());
				args.push("--append-system-prompt", notePath);

				let sessionId: string | undefined;
				let stderr = "";
				let aborted = false;
				let exitSignal: string | null = null;
				let stray = ""; // non-JSON stdout, kept for diagnostics
				const inv = getPiInvocation(args);

				const exitCode = await new Promise<number>((resolve) => {
					const child = spawn(inv.command, inv.args, {
						cwd,
						shell: false,
						stdio: ["pipe", "pipe", "pipe"],
						env: {
							...process.env,
							PI_SUBAGENT_DEPTH: String(DEPTH + 1),
							// Don't let the child report agent state for the parent's terminal pane.
							HERDR_ENV: "",
							HERDR_PANE_ID: "",
						},
					});
					children.add(child);
					// Piped stdin becomes the prompt verbatim (no option/@file parsing, no length limit).
					child.stdin!.on("error", () => {}); // child may exit before reading (e.g. bad model)
					child.stdin!.end(params.prompt);

					let buffer = "";
					const handle = (line: string) => {
						if (!line.trim()) return;
						let ev: any;
						try {
							ev = JSON.parse(line);
						} catch {
							if (stray.length < 4000) stray += `${line}\n`;
							return;
						}
						switch (ev.type) {
							case "session":
								sessionId = ev.id;
								details.sessionFile = findSessionFile(sessionDir, sessionId);
								break;
							case "tool_execution_start":
								details.toolCalls++;
								pushActivity({
									kind: "tool",
									id: ev.toolCallId,
									name: ev.toolName,
									preview: toolPreview(ev.toolName, ev.args),
									status: "running",
								});
								emit();
								break;
							case "tool_execution_end": {
								const a = details.activity.find((x) => x.kind === "tool" && x.id === ev.toolCallId);
								if (a?.kind === "tool") a.status = ev.isError ? "error" : "ok";
								emit();
								break;
							}
							case "message_end": {
								const msg = ev.message;
								if (msg?.role !== "assistant") break;
								details.usage.turns++;
								const u = msg.usage;
								if (u) {
									details.usage.input += u.input || 0;
									details.usage.output += u.output || 0;
									details.usage.cacheRead += u.cacheRead || 0;
									details.usage.cacheWrite += u.cacheWrite || 0;
									details.usage.totalTokens += u.totalTokens || 0;
									details.usage.cost += u.cost?.total || 0;
									details.usage.contextTokens = u.totalTokens || 0;
								}
								if (msg.provider && msg.model) details.model = `${msg.provider}/${msg.model}`;
								if (msg.thinkingLevel) details.thinking = msg.thinkingLevel;
								if (msg.stopReason) details.stopReason = msg.stopReason;
								if (msg.errorMessage) details.error = msg.errorMessage;
								const text = (msg.content ?? [])
									.filter((p: any) => p.type === "text")
									.map((p: any) => p.text)
									.join("\n")
									.trim();
								if (text) {
									details.output = text;
									pushActivity({ kind: "text", text });
								}
								emit();
								break;
							}
						}
					};

					child.stdout!.on("data", (chunk) => {
						buffer += chunk.toString();
						const lines = buffer.split("\n");
						buffer = lines.pop() ?? "";
						for (const l of lines) handle(l);
					});
					child.stderr!.on("data", (chunk) => {
						stderr += chunk.toString();
						if (stderr.length > 20_000) stderr = stderr.slice(-20_000);
					});
					child.on("close", (code, sig) => {
						children.delete(child);
						if (buffer.trim()) handle(buffer);
						exitSignal = sig;
						resolve(code ?? 1);
					});
					child.on("error", (err) => {
						children.delete(child);
						stderr += `\n${err.message}`;
						resolve(1);
					});

					const kill = () => {
						aborted = true;
						child.kill("SIGTERM");
						setTimeout(() => child.exitCode === null && child.kill("SIGKILL"), 5000).unref();
					};
					if (signal?.aborted) kill();
					else signal?.addEventListener("abort", kill, { once: true });
				});

				details.sessionFile ??= findSessionFile(sessionDir, sessionId);
				// Strip terminal escape sequences (e.g. notification OSCs) from diagnostics.
				// biome-ignore lint/suspicious/noControlCharactersInRegex: intentional
				const cleanErr = stderr.replace(/\x1b\][^\x07]*(\x07|\x1b\\)|\x1b\[[0-9;?]*[A-Za-z]/g, "").trim();

				if (aborted) {
					details.status = "aborted";
					details.error = "Subagent was aborted";
				} else if (exitCode !== 0 || details.stopReason === "error" || details.stopReason === "aborted" || !details.output) {
					details.status = "error";
					const diag = [
						`exit code ${exitCode}${exitSignal ? ` (signal ${exitSignal})` : ""}${sessionId ? "" : ", no session started"}`,
						`command: ${[inv.command, ...inv.args].map((a) => oneLine(a, 80)).join(" ")} < prompt (${params.prompt.length} chars)`,
						cleanErr && `stderr: ${cleanErr.slice(-2000)}`,
						stray.trim() && `stdout: ${stray.trim().slice(-1000)}`,
					]
						.filter(Boolean)
						.join("\n");
					const reason = details.error || (details.output ? undefined : "Subagent produced no output");
					details.error = [reason, diag].filter(Boolean).join("\n");
				} else {
					details.status = "done";
				}
			} catch (err) {
				details.status = signal?.aborted ? "aborted" : "error";
				details.error = err instanceof Error ? err.message : String(err);
			} finally {
				release?.();
			}
			return finish();
		},

		renderCall(args, theme) {
			const model = [args.model || "current model", args.thinking].filter(Boolean).join(":");
			const label = args.label || (args.prompt ? oneLine(args.prompt, 50) : "…");
			let text = `${theme.fg("toolTitle", theme.bold("subagent "))}${theme.fg("accent", label)}${theme.fg("muted", ` [${model}]`)}`;
			if (args.prompt) text += `\n${theme.fg("dim", oneLine(args.prompt, 160))}`;
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded, isPartial }, theme) {
			const d = result.details as SubagentDetails | undefined;
			if (!d) {
				const c = result.content[0];
				return new Text(c?.type === "text" ? c.text : "(no output)", 0, 0);
			}
			const icon =
				d.status === "running" || isPartial
					? theme.fg("warning", "⏳")
					: d.status === "done"
						? theme.fg("success", "✓")
						: theme.fg("error", "✗");
			const header = `${icon} ${theme.fg("toolTitle", theme.bold(d.label))} ${theme.fg("dim", formatStats(d))}`;
			const activityLine = (a: Activity) =>
				a.kind === "tool"
					? `${theme.fg("muted", "→ ")}${theme.fg("accent", a.name)} ${theme.fg("toolOutput", oneLine(a.preview, 100))}`
					: theme.fg("dim", oneLine(a.text, 120));

			if (!expanded) {
				let text = header;
				if (d.error && d.status !== "running") text += `\n${theme.fg("error", `Error: ${oneLine(d.error, 300)}`)}`;
				if (d.status === "done") {
					const preview = d.output.split("\n").slice(0, 4).join("\n");
					text += `\n${theme.fg("toolOutput", preview)}`;
					if (d.output.split("\n").length > 4) text += `\n${theme.fg("muted", "… (Ctrl+O to expand)")}`;
				} else {
					const recent = d.activity.slice(-COLLAPSED_ACTIVITY);
					if (recent.length === 0) text += `\n${theme.fg("muted", "(starting…)")}`;
					for (const a of recent) text += `\n${activityLine(a)}`;
				}
				return new Text(text, 0, 0);
			}

			const box = new Container();
			box.addChild(new Text(header, 0, 0));
			if (d.sessionFile) box.addChild(new Text(theme.fg("muted", `session: ${shortenPath(d.sessionFile)}`), 0, 0));
			if (d.error) box.addChild(new Text(theme.fg("error", `Error: ${d.error}`), 0, 0));
			box.addChild(new Spacer(1));
			box.addChild(new Text(theme.fg("muted", "─── Prompt ───"), 0, 0));
			box.addChild(new Text(theme.fg("dim", d.prompt), 0, 0));
			const tools = d.activity.filter((a) => a.kind === "tool");
			if (tools.length) {
				box.addChild(new Spacer(1));
				box.addChild(new Text(theme.fg("muted", `─── Activity (last ${tools.length} of ${d.toolCalls}) ───`), 0, 0));
				box.addChild(new Text(tools.map(activityLine).join("\n"), 0, 0));
			}
			if (d.output) {
				box.addChild(new Spacer(1));
				box.addChild(new Text(theme.fg("muted", "─── Result ───"), 0, 0));
				box.addChild(new Markdown(d.output.trim(), 0, 0, getMarkdownTheme()));
			}
			return box;
		},
	});
}
