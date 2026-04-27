import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { getAgentDir, parseFrontmatter } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { randomUUID } from "node:crypto";

type PipelineTemplate = {
  id: string;
  description: string;
  path: string;
  steps: string[];
};

type PipelineDraft = {
  id: string;
  selector: string;
  goal: string;
  steps: string[];
  createdAt: number;
  runDir: string;
};

type PipelineState = {
  pendingDraft: PipelineDraft | null;
};

const STATE_ENTRY = "pipeline-state";
const WIDGET_KEY = "pipeline";

function isGoSignal(input: string): boolean {
  const normalized = input.trim().toLowerCase();
  return /^(good to go|go for it|looks good|approved|run it|ship it|yes,? run|y)$/i.test(normalized);
}

function parseOrderedSteps(markdown: string): string[] {
  const lines = markdown.split(/\r?\n/);
  const steps = lines
    .map((line) => line.trim())
    .filter((line) => /^(?:\d+\.|[-*]\s+(?:\[[ xX]\]\s+)?)\s+/.test(line))
    .map((line) => line.replace(/^(?:\d+\.|[-*]\s+(?:\[[ xX]\]\s+)?)\s+/, "").trim())
    .filter(Boolean);

  return steps;
}

function renderDraftMessage(draft: PipelineDraft): string {
  const numbered = draft.steps.map((step, index) => `${index + 1}. ${step}`).join("\n");
  return [
    `Pipeline draft (${draft.selector})`,
    "",
    `Goal: ${draft.goal}`,
    "",
    numbered || "(No steps yet)",
    "",
    "Reply with edits you want.",
    'When ready, reply exactly like: "good to go"',
  ].join("\n");
}

function setPipelineUI(ctx: ExtensionContext, state: PipelineState): void {
  if (!state.pendingDraft) {
    ctx.ui.setStatus("pipeline", undefined);
    ctx.ui.setWidget(WIDGET_KEY, undefined);
    return;
  }

  const draft = state.pendingDraft;
  ctx.ui.setStatus("pipeline", ctx.ui.theme.fg("accent", `pipeline:draft (${draft.selector})`));

  const lines = [
    ctx.ui.theme.fg("accent", "Pipeline Draft Pending Approval"),
    ctx.ui.theme.fg("muted", `Mode: ${draft.selector}`),
    ctx.ui.theme.fg("muted", `Goal: ${draft.goal}`),
    "",
    ...draft.steps.map((step, index) => `${ctx.ui.theme.fg("dim", `${index + 1}.`)} ${step}`),
    "",
    ctx.ui.theme.fg("warning", 'Reply "good to go" to execute (execution stub for now).'),
  ];

  ctx.ui.setWidget(WIDGET_KEY, lines);
}

async function readLastState(ctx: ExtensionContext): Promise<PipelineState> {
  const entries = ctx.sessionManager.getEntries();
  const last = [...entries]
    .reverse()
    .find((entry) => entry.type === "custom" && (entry as { customType?: string }).customType === STATE_ENTRY) as
    | { data?: PipelineState }
    | undefined;

  return {
    pendingDraft: last?.data?.pendingDraft ?? null,
  };
}

function persistState(pi: ExtensionAPI, state: PipelineState): void {
  pi.appendEntry(STATE_ENTRY, state);
}

async function ensureScratchpadWorkspace(projectRoot: string, ctx: ExtensionContext): Promise<void> {
  const scratchpadDir = join(projectRoot, ".scratchpad");
  await mkdir(scratchpadDir, { recursive: true });

  const gitignorePath = join(projectRoot, ".gitignore");
  let current = "";

  try {
    current = await readFile(gitignorePath, "utf8");
  } catch {
    // missing file; we will create below
  }

  const lines = current.split(/\r?\n/).map((line) => line.trim());
  const hasIgnore = lines.some((line) => line === ".scratchpad/" || line === ".scratchpad");
  if (hasIgnore) return;

  const hasExplicitUnignore = lines.some((line) => line === "!.scratchpad/" || line === "!.scratchpad");
  if (hasExplicitUnignore) {
    ctx.ui.notify("Found !.scratchpad rule in .gitignore; leaving ignore rules unchanged.", "warning");
    return;
  }

  const suffix = current.length > 0 && !current.endsWith("\n") ? "\n" : "";
  const next = `${current}${suffix}.scratchpad/\n`;
  await mkdir(dirname(gitignorePath), { recursive: true });
  await writeFile(gitignorePath, next, "utf8");
}

async function collectTemplatesFrom(dir: string): Promise<PipelineTemplate[]> {
  let fileNames: string[] = [];

  try {
    const info = await stat(dir);
    if (!info.isDirectory()) return [];
    fileNames = await readdir(dir);
  } catch {
    return [];
  }

  const templates: PipelineTemplate[] = [];

  for (const name of fileNames) {
    if (!name.endsWith(".md")) continue;

    const path = join(dir, name);
    let raw = "";
    try {
      raw = await readFile(path, "utf8");
    } catch {
      continue;
    }

    const { frontmatter, body } = parseFrontmatter<Record<string, string>>(raw);
    const id = (frontmatter.name || name.replace(/\.md$/, "")).trim();
    const description = (frontmatter.description || "Pipeline template").trim();
    const steps = parseOrderedSteps(body);

    templates.push({ id, description, path, steps });
  }

  return templates;
}

async function loadTemplates(cwd: string): Promise<PipelineTemplate[]> {
  const globalDir = join(getAgentDir(), "pipelines");
  const projectDir = join(cwd, ".pi", "pipelines");

  const [globalTemplates, projectTemplates] = await Promise.all([
    collectTemplatesFrom(globalDir),
    collectTemplatesFrom(projectDir),
  ]);

  // Project templates override global templates by id.
  const byId = new Map<string, PipelineTemplate>();
  for (const template of globalTemplates) byId.set(template.id, template);
  for (const template of projectTemplates) byId.set(template.id, template);

  return [...byId.values()].sort((a, b) => a.id.localeCompare(b.id));
}

function makeAutoDraftSteps(goal: string): string[] {
  return [
    `Clarify success criteria for: ${goal}`,
    "Plan execution steps and dependencies",
    "Execute steps via fresh subagent contexts",
    "Aggregate outputs, summarize, and report costs",
  ];
}

function parsePipelineArgs(args: string): { selector: string; goal: string } | null {
  const trimmed = args.trim();
  if (!trimmed) return null;

  const match = trimmed.match(/^(\S+)\s*([\s\S]*)$/);
  if (!match) return null;

  const selector = match[1].trim();
  const goal = (match[2] || "").trim();
  return { selector, goal };
}

export default function pipelineExtension(pi: ExtensionAPI): void {
  let state: PipelineState = { pendingDraft: null };

  pi.registerCommand("pipeline", {
    description: "Create a pipeline draft and wait for approval",
    getArgumentCompletions: (prefix) => {
      const base = [
        { value: "auto", label: "auto", description: "Generate a dynamic pipeline draft" },
        { value: "status", label: "status", description: "Show current pipeline draft state" },
      ];
      const staticTemplates = [
        { value: "design", label: "design", description: "Run the design pipeline template" },
      ];

      const items = [...base, ...staticTemplates].filter((item) => item.value.startsWith(prefix));
      return items.length > 0 ? items : null;
    },
    handler: async (args, ctx) => {
      const templates = await loadTemplates(ctx.cwd);

      let selector = "";
      let goal = "";

      if (!args.trim() && ctx.hasUI) {
        const choices = ["auto", ...templates.map((t) => t.id)];
        const picked = await ctx.ui.select("Choose pipeline mode/template", choices);
        if (!picked) return;

        const askedGoal = await ctx.ui.editor("What do you want this pipeline to accomplish?", "");
        if (!askedGoal?.trim()) {
          ctx.ui.notify("Cancelled: missing goal text.", "warning");
          return;
        }

        selector = picked;
        goal = askedGoal.trim();
      } else {
        const parsed = parsePipelineArgs(args);
        if (!parsed) {
          ctx.ui.notify("Usage: /pipeline <auto|template> <goal>", "warning");
          return;
        }
        selector = parsed.selector;
        goal = parsed.goal;
      }

      if (selector === "status") {
        if (!state.pendingDraft) {
          ctx.ui.notify("No pending pipeline draft.", "info");
          return;
        }

        setPipelineUI(ctx, state);
        pi.sendMessage(
          {
            customType: "pipeline",
            content: renderDraftMessage(state.pendingDraft),
            display: true,
            details: { draftId: state.pendingDraft.id, selector: state.pendingDraft.selector },
          },
          { triggerTurn: false },
        );
        return;
      }

      if (!goal) {
        ctx.ui.notify("Missing goal text. Example: /pipeline:auto Build a design workflow", "warning");
        return;
      }

      await ensureScratchpadWorkspace(ctx.cwd, ctx);

      const template = selector === "auto" ? undefined : templates.find((t) => t.id === selector);
      if (selector !== "auto" && !template) {
        const available = templates.map((t) => t.id).join(", ") || "(none)";
        ctx.ui.notify(`Unknown template \"${selector}\". Available: ${available}`, "error");
        return;
      }

      const draftId = randomUUID().slice(0, 8);
      const runDir = join(ctx.cwd, ".scratchpad", "pipelines", draftId);
      await mkdir(runDir, { recursive: true });

      const draft: PipelineDraft = {
        id: draftId,
        selector,
        goal,
        steps: template?.steps.length ? template.steps : makeAutoDraftSteps(goal),
        createdAt: Date.now(),
        runDir,
      };

      // Save plan artifact to scratchpad immediately for traceability.
      await writeFile(join(runDir, "draft-plan.md"), renderDraftMessage(draft), "utf8");

      state.pendingDraft = draft;
      persistState(pi, state);
      setPipelineUI(ctx, state);

      pi.sendMessage(
        {
          customType: "pipeline",
          content: renderDraftMessage(draft),
          display: true,
          details: { draftId: draft.id, selector: draft.selector, runDir: draft.runDir },
        },
        { triggerTurn: false },
      );
    },
  });

  // Alias support: /pipeline:auto ... and /pipeline:<template> ...
  pi.on("input", async (event, _ctx) => {
    if (event.text.startsWith("/pipeline:")) {
      const match = event.text.match(/^\/pipeline:([^\s]+)\s*([\s\S]*)$/);
      if (match) {
        const selector = match[1];
        const rest = (match[2] || "").trim();
        const transformed = rest ? `/pipeline ${selector} ${rest}` : `/pipeline ${selector}`;
        return { action: "transform", text: transformed };
      }
    }

    if (!state.pendingDraft) return { action: "continue" };

    if (event.source === "extension") return { action: "continue" };

    // No questionnaire flow: normal conversation is allowed until explicit go signal.
    if (isGoSignal(event.text)) {
      const draft = state.pendingDraft;
      state.pendingDraft = null;
      persistState(pi, state);

      pi.sendMessage(
        {
          customType: "pipeline",
          content: [
            `Pipeline approved: ${draft.selector}`,
            `Run directory: ${draft.runDir}`,
            "",
            "Execution skeleton only right now.",
            "TODO next: spawn subagents per step and stream usage/cost per step.",
          ].join("\n"),
          display: true,
          details: { draftId: draft.id, runDir: draft.runDir },
        },
        { triggerTurn: false },
      );

      return { action: "handled" };
    }

    return { action: "continue" };
  });

  pi.on("session_start", async (_event, ctx) => {
    state = await readLastState(ctx);
    setPipelineUI(ctx, state);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    ctx.ui.setStatus("pipeline", undefined);
    ctx.ui.setWidget(WIDGET_KEY, undefined);
  });
}
