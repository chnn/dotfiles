/**
 * Session Title Extension
 *
 * After the first prompt of an unnamed session, asks an LLM for a short title
 * (< 80 chars), then sets it as the session name (like `/name <title>`) and as
 * the terminal title.
 *
 * Model: the current session model by default. Override with
 *   PI_SESSION_TITLE_MODEL=<provider>/<model-id>
 */

import path from "node:path";
import type { Api, Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MAX_TITLE_LENGTH = 79;
const MAX_PROMPT_CHARS = 4000;

const SYSTEM_PROMPT = `You generate short titles for coding-assistant chat sessions.
Given the user's first message, reply with ONLY a concise, descriptive title:
- fewer than 80 characters (aim for 3-8 words)
- no surrounding quotes, no trailing punctuation, no markdown, no emoji
- plain text on a single line`;

function resolveModel(ctx: ExtensionContext): Model<Api> | undefined {
	const override = process.env.PI_SESSION_TITLE_MODEL?.trim();
	if (override) {
		const slash = override.indexOf("/");
		if (slash > 0) {
			const model = ctx.modelRegistry.find(override.slice(0, slash), override.slice(slash + 1));
			if (model && ctx.modelRegistry.hasConfiguredAuth(model)) return model;
		}
	}
	return ctx.model;
}

function cleanTitle(raw: string): string {
	let title = raw.split("\n").map((l) => l.trim()).find((l) => l.length > 0) ?? "";
	title = title
		.replace(/^(title|session title)\s*:\s*/i, "")
		.replace(/^[#*\s]+|[*\s]+$/g, "")
		.replace(/^["'`“”‘’]+|["'`“”‘’]+$/g, "")
		.replace(/[.\s]+$/, "")
		.replace(/\s+/g, " ")
		.trim();
	if (title.length > MAX_TITLE_LENGTH) {
		const cut = title.slice(0, MAX_TITLE_LENGTH - 1);
		const lastSpace = cut.lastIndexOf(" ");
		title = `${(lastSpace > 40 ? cut.slice(0, lastSpace) : cut).trimEnd()}…`;
	}
	return title;
}

function terminalTitle(name: string, cwd: string): string {
	return `π - ${name} - ${path.basename(cwd)}`;
}

export default function (pi: ExtensionAPI) {
	let attempted = false;
	let controller: AbortController | undefined;

	function reset() {
		controller?.abort();
		controller = undefined;
		attempted = false;
	}

	pi.on("session_start", () => reset());
	pi.on("session_shutdown", () => reset());

	pi.on("before_agent_start", (event, ctx) => {
		if (event.messageType !== "user") return;
		if (attempted || pi.getSessionName()) return;
		const prompt = event.prompt.trim();
		if (!prompt) return;

		const model = resolveModel(ctx);
		if (!model) return;

		attempted = true;
		const sessionId = ctx.sessionManager.getSessionId();
		const cwd = ctx.sessionManager.getCwd();
		const abort = new AbortController();
		controller = abort;

		// Fire and forget: don't block the agent run on title generation.
		void (async () => {
			try {
				const response = await ctx.modelRegistry
					.streamSimple(
						model,
						{
							systemPrompt: SYSTEM_PROMPT,
							messages: [
								{
									role: "user",
									content: [
										{
											type: "text",
											text: `<first_message>\n${prompt.slice(0, MAX_PROMPT_CHARS)}\n</first_message>\n\nReply with the title only.`,
										},
									],
									timestamp: Date.now(),
								},
							],
						},
						{ signal: abort.signal, cacheRetention: "none", reasoning: model.reasoning ? "minimal" : undefined },
					)
					.result();

				if (abort.signal.aborted || response.stopReason === "aborted" || response.stopReason === "error") return;

				const text = response.content
					.filter((c): c is { type: "text"; text: string } => c.type === "text")
					.map((c) => c.text)
					.join("\n");
				const title = cleanTitle(text);
				if (!title) return;

				// Bail if the session changed or the user named it meanwhile.
				if (ctx.sessionManager.getSessionId() !== sessionId || pi.getSessionName()) return;

				pi.setSessionName(title);
				if (ctx.mode === "tui") ctx.ui.setTitle(terminalTitle(title, cwd));
			} catch {
				// Title generation is best-effort; ignore failures.
			} finally {
				if (controller === abort) controller = undefined;
			}
		})();
	});
}
