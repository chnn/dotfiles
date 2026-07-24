import { access, mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, join } from "node:path";

import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { Api, AssistantMessage, Model, TextContent } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const STATUS_ID = "plan-mode";
const STATE_ENTRY_TYPE = "plan-mode-state";
const PLANS_DIRECTORY = join(homedir(), ".pi", "agent", "plans");
const READ_ONLY_TOOL_NAMES = new Set(["read", "grep", "find", "ls"]);
const PLAN_START_MARKER = "<!-- PI_PLAN_START -->";
const PLAN_END_MARKER = "<!-- PI_PLAN_END -->";

interface PlanModeState {
  enabled: boolean;
  planPath?: string;
  toolsBeforePlanMode?: string[];
}

function isAssistantMessage(message: AgentMessage): message is AssistantMessage {
  return message.role === "assistant" && Array.isArray(message.content);
}

function getAssistantText(message: AssistantMessage): string {
  return message.content
    .filter((content): content is TextContent => content.type === "text")
    .map((content) => content.text)
    .join("\n");
}

function extractPlan(text: string): string | undefined {
  const escapedStart = PLAN_START_MARKER.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const escapedEnd = PLAN_END_MARKER.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const matches = [
    ...text.matchAll(new RegExp(`${escapedStart}\\s*([\\s\\S]*?)\\s*${escapedEnd}`, "g")),
  ];
  const plan = matches.at(-1)?.[1]?.trim();
  return plan ? `${plan}\n` : undefined;
}

function slugifyPlan(plan: string): string {
  const heading = plan.match(/^#\s+(.+)$/m)?.[1] ?? "plan";
  return (
    heading
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60) || "plan"
  );
}

function timestampForFile(date = new Date()): string {
  return date.toISOString().replace(/[-:]/g, "").replace("T", "-").slice(0, 15);
}

async function createPlanPath(plan: string): Promise<string> {
  await mkdir(PLANS_DIRECTORY, { recursive: true });

  const stem = `${timestampForFile()}-${slugifyPlan(plan)}`;
  for (let suffix = 0; suffix < 1000; suffix++) {
    const fileName = `${stem}${suffix === 0 ? "" : `-${suffix + 1}`}.md`;
    const path = join(PLANS_DIRECTORY, fileName);
    try {
      await access(path);
    } catch {
      return path;
    }
  }

  throw new Error("Could not allocate a unique plan filename");
}

async function findLatestPlan(): Promise<string | undefined> {
  try {
    const entries = await readdir(PLANS_DIRECTORY, { withFileTypes: true });
    const plans = await Promise.all(
      entries
        .filter((entry) => entry.isFile() && entry.name.endsWith(".md"))
        .map(async (entry) => {
          const path = join(PLANS_DIRECTORY, entry.name);
          return { path, modifiedAt: (await stat(path)).mtimeMs };
        }),
    );
    return plans.sort((left, right) => right.modifiedAt - left.modifiedAt)[0]?.path;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return undefined;
    throw error;
  }
}

function uniqueModels(models: Model<Api>[]): Model<Api>[] {
  const seen = new Set<string>();
  return models.filter((model) => {
    const reference = `${model.provider}/${model.id}`;
    if (seen.has(reference)) return false;
    seen.add(reference);
    return true;
  });
}

async function pickModel(
  ctx: ExtensionCommandContext,
  planPath: string,
): Promise<Model<Api> | undefined> {
  const scopedModels = ctx.scopedModels.map(({ model }) => model as Model<Api>);
  const models = uniqueModels(
    scopedModels.length > 0 ? scopedModels : ctx.modelRegistry.getAvailable(),
  ).sort((left, right) => {
    const leftIsCurrent = left.provider === ctx.model?.provider && left.id === ctx.model.id;
    const rightIsCurrent = right.provider === ctx.model?.provider && right.id === ctx.model.id;
    if (leftIsCurrent !== rightIsCurrent) return leftIsCurrent ? -1 : 1;
    return `${left.provider}/${left.id}`.localeCompare(`${right.provider}/${right.id}`);
  });

  if (models.length === 0) {
    ctx.ui.notify("No authenticated models are available", "error");
    return undefined;
  }

  const modelByLabel = new Map<string, Model<Api>>();
  for (const model of models) {
    const reference = `${model.provider}/${model.id}`;
    const name = model.name && model.name !== model.id ? ` — ${model.name}` : "";
    const current = model.provider === ctx.model?.provider && model.id === ctx.model.id;
    modelByLabel.set(`${reference}${name}${current ? " (current)" : ""}`, model);
  }

  const choice = await ctx.ui.select(`Implement ${basename(planPath)} with which model?`, [
    ...modelByLabel.keys(),
  ]);
  return choice ? modelByLabel.get(choice) : undefined;
}

export default function planModeExtension(pi: ExtensionAPI): void {
  let planModeEnabled = false;
  let activePlanPath: string | undefined;
  let toolsBeforePlanMode: string[] | undefined;

  function persistState(): void {
    pi.appendEntry<PlanModeState>(STATE_ENTRY_TYPE, {
      enabled: planModeEnabled,
      planPath: activePlanPath,
      toolsBeforePlanMode,
    });
  }

  function updateStatus(ctx: ExtensionContext): void {
    const label = activePlanPath ? `plan: ${basename(activePlanPath)}` : "plan mode";
    ctx.ui.setStatus(STATUS_ID, planModeEnabled ? ctx.ui.theme.fg("warning", label) : undefined);
  }

  function enableReadOnlyTools(): void {
    if (toolsBeforePlanMode === undefined) {
      toolsBeforePlanMode = pi.getActiveTools();
    }

    const availableTools = new Set(pi.getAllTools().map((tool) => tool.name));
    pi.setActiveTools([...READ_ONLY_TOOL_NAMES].filter((toolName) => availableTools.has(toolName)));
  }

  async function beginPlanMode(ctx: ExtensionCommandContext, topic: string): Promise<void> {
    if (!planModeEnabled) {
      planModeEnabled = true;
      activePlanPath = undefined;
      enableReadOnlyTools();
      updateStatus(ctx);
      persistState();
      ctx.ui.notify("Plan mode enabled. Only read-only exploration tools are available.", "info");
    } else {
      enableReadOnlyTools();
      ctx.ui.notify("Plan mode is already active", "info");
    }

    if (topic) {
      pi.sendUserMessage(`Develop an implementation plan for the following change:\n\n${topic}`);
    }
  }

  pi.registerCommand("plan", {
    description: "Enter read-only plan mode",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();
      await beginPlanMode(ctx, args.trim());
    },
  });

  pi.registerCommand("implement", {
    description: "Start a new session and implement the current plan with a selected model",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/implement requires an interactive UI", "error");
        return;
      }

      await ctx.waitForIdle();

      let planPath = activePlanPath;
      try {
        if (planPath) {
          await access(planPath);
        } else {
          planPath = await findLatestPlan();
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Could not find the plan: ${message}`, "error");
        return;
      }

      if (!planPath) {
        ctx.ui.notify("No saved plan found. Finish a plan with /plan first.", "error");
        return;
      }

      const model = await pickModel(ctx, planPath);
      if (!model) return;

      const previousModel = ctx.model;
      if (!(await pi.setModel(model))) {
        ctx.ui.notify(`No credentials are available for ${model.provider}/${model.id}`, "error");
        return;
      }

      const selectedProvider = model.provider;
      const selectedModelId = model.id;
      const implementationPrompt = `Implement the plan at ${JSON.stringify(planPath)}.\n\nRead the plan file first, then carry out the full plan. Make the required code changes, run the relevant checks, and report the result.`;

      const result = await ctx.newSession({
        setup: async (sessionManager) => {
          sessionManager.appendModelChange(selectedProvider, selectedModelId);
        },
        withSession: async (replacementCtx) => {
          await replacementCtx.sendUserMessage(implementationPrompt);
        },
      });

      if (result.cancelled) {
        if (previousModel) await pi.setModel(previousModel);
        ctx.ui.notify("Starting the implementation session was cancelled", "info");
      }
    },
  });

  pi.on("tool_call", (event) => {
    if (!planModeEnabled || READ_ONLY_TOOL_NAMES.has(event.toolName)) return;
    return {
      block: true,
      reason: `Plan mode only permits read-only exploration tools. ${event.toolName} is disabled.`,
    };
  });

  pi.on("before_agent_start", async (event) => {
    if (!planModeEnabled) return;

    let currentPlan = "";
    if (activePlanPath) {
      try {
        currentPlan = await readFile(activePlanPath, "utf8");
      } catch {
        // The conversation still contains the prior plan, so planning can continue.
      }
    }

    const existingPlanInstructions = activePlanPath
      ? `\n\nA plan is already saved at ${activePlanPath}. Treat user suggestions as requested revisions. When the revision is ready, output the entire revised plan, not a diff or a summary.${currentPlan ? `\n\nCurrent saved plan:\n<current-plan>\n${currentPlan}\n</current-plan>` : ""}`
      : "";

    return {
      systemPrompt: `${event.systemPrompt}\n\n[PLAN MODE]\nYou are in a collaborative, read-only planning discussion. Explore the repository thoroughly with the available read-only tools before committing to an approach. Do not edit files, run commands, implement code, or make any other project changes.\n\nDiscuss discoveries and tradeoffs with the user. Ask a focused clarifying question when an answer would materially improve the plan; do not manufacture questions when the intent is already clear. A question may be your whole response, and you should continue planning after the user answers.\n\nWhen you determine the plan is ready, print one complete, standalone Markdown plan. It should name relevant files, explain the implementation steps and important decisions, and include validation, tests, risks, and edge cases where applicable. Wrap only the complete plan in these exact invisible markers:\n${PLAN_START_MARKER}\n# Plan title\n...full plan...\n${PLAN_END_MARKER}\nThe extension will save text between those markers, so never claim that you wrote the file yourself. Do not emit the markers for tentative notes or while asking a question.${existingPlanInstructions}`,
    };
  });

  pi.on("message_end", async (event, ctx) => {
    if (!planModeEnabled || !isAssistantMessage(event.message)) return;

    const plan = extractPlan(getAssistantText(event.message));
    if (!plan) return;

    try {
      activePlanPath ??= await createPlanPath(plan);
      await mkdir(PLANS_DIRECTORY, { recursive: true });
      await writeFile(activePlanPath, plan, "utf8");
      persistState();
      updateStatus(ctx);
      ctx.ui.notify(`Plan saved to ${activePlanPath}`, "info");
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Could not save plan: ${message}`, "error");
    }
  });

  pi.on("session_start", (_event, ctx) => {
    const stateEntry = ctx.sessionManager
      .getBranch()
      .filter(
        (entry): entry is typeof entry & { type: "custom"; data?: PlanModeState } =>
          entry.type === "custom" && entry.customType === STATE_ENTRY_TYPE,
      )
      .at(-1);

    if (stateEntry?.data) {
      planModeEnabled = stateEntry.data.enabled;
      activePlanPath = stateEntry.data.planPath;
      toolsBeforePlanMode = stateEntry.data.toolsBeforePlanMode;
    }

    if (planModeEnabled) enableReadOnlyTools();
    updateStatus(ctx);
  });
}
