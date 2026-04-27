import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@mariozechner/pi-coding-agent";
import { getAgentDir, parseFrontmatter } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { join } from "node:path";

type PipelineTemplate = {
  name: string;
  description: string;
  path: string;
  body: string;
};

const SCRATCHPAD_DIR = ".scratchpad";
const PIPELINE_PATH = join(SCRATCHPAD_DIR, "PIPELINE.md");
const GITIGNORE_ENTRY = ".scratchpad/";

async function pipelineTemplates(): Promise<PipelineTemplate[]> {
  const globalDir = join(getAgentDir(), "pipelines");

  let files: string[] = [];
  try {
    files = await readdir(globalDir);
  } catch {
    return [];
  }

  const templates: PipelineTemplate[] = [];
  for (const file of files) {
    if (!file.endsWith(".md")) continue;

    const path = join(globalDir, file);
    let raw = "";
    try {
      raw = await readFile(path, "utf8");
    } catch {
      continue;
    }

    const { frontmatter, body } = parseFrontmatter<Record<string, string>>(raw);
    const name = (frontmatter.name || file.replace(/\.md$/, "")).trim();
    const description = (frontmatter.description || "Pipeline template").trim();

    templates.push({ name, description, path, body: body.trim() });
  }

  return templates;
}

async function ensureScratchpadAndGitignore(cwd: string): Promise<void> {
  await mkdir(join(cwd, SCRATCHPAD_DIR), { recursive: true });

  const gitignorePath = join(cwd, ".gitignore");
  let content = "";
  try {
    content = await readFile(gitignorePath, "utf8");
  } catch {
    content = "";
  }

  const hasEntry = content
    .split(/\r?\n/)
    .some((line) => line.trim() === GITIGNORE_ENTRY || line.trim() === ".scratchpad");

  if (!hasEntry) {
    const prefix = content.length > 0 && !content.endsWith("\n") ? "\n" : "";
    await writeFile(gitignorePath, `${content}${prefix}${GITIGNORE_ENTRY}\n`, "utf8");
  }
}

async function seedPipelineFile(
  cwd: string,
  goal: string,
  mode: "dynamic" | "templated",
  template?: PipelineTemplate,
): Promise<string> {
  const header = [
    "# Pipeline",
    `Goal: ${goal}`,
    `Mode: ${mode}`,
    "Approved: false",
    "Status: draft",
    "",
  ];

  const defaultSteps = [
    "1) [ ] Discover and collect inputs [agent: standard]",
    "    - [ ] Locate candidate sources and write list [agent: fast]",
    "    - [ ] Filter sources for relevance and quality [agent: standard]",
    "2) [ ] Process source material [agent: standard]",
    "    - [ ] Extract content in parallel batches [agent: fast]",
    "    - [ ] Summarize each batch to artifacts [agent: fast]",
    "3) [ ] Synthesize final output [agent: deep]",
  ];

  const templateBlock =
    template && template.body
      ? [
          "",
          "## Template guidance",
          `Template: ${template.name}`,
          "",
          template.body,
        ]
      : [];

  const content = [...header, ...defaultSteps, ...templateBlock, ""].join("\n");
  const pipelineFile = join(cwd, PIPELINE_PATH);
  await writeFile(pipelineFile, content, "utf8");
  return pipelineFile;
}

function buildKickoffPrompt(goal: string, template?: PipelineTemplate): string {
  const lines = [
    `/skill:pipeline ${goal}`,
    "",
    "Hard execution contract:",
    "1) Start by creating/updating .scratchpad/PIPELINE.md only.",
    "2) Every step/substep must include [agent: fast|standard|deep].",
    "3) Present the draft pipeline and ask for approval.",
    "4) Do not execute any pipeline step until approved.",
    "5) On approval, update PIPELINE.md once: Approved: true + Status: running in the same edit.",
    "6) After approval, execute steps via the subagent tool.",
    "7) If a top-level step has multiple unchecked substeps, run them together in ONE parallel subagent call using tasks[].",
    "8) Do not execute sibling substeps sequentially when parallel execution is possible.",
  ];

  if (template) {
    lines.push(
      "",
      `Template selected: ${template.name}`,
      "Incorporate this template guidance into the draft:",
      template.body || "(No body provided)",
    );
  }

  return lines.join("\n");
}

async function kickoffPipeline(
  pi: ExtensionAPI,
  args: string,
  ctx: ExtensionCommandContext,
  template?: PipelineTemplate,
): Promise<void> {
  const goal = args.trim();
  if (!goal) {
    ctx.ui.notify("Usage: /pipeline:auto <goal>", "error");
    return;
  }

  await ensureScratchpadAndGitignore(ctx.cwd);
  const mode = template ? "templated" : "dynamic";
  const pipelineFile = await seedPipelineFile(ctx.cwd, goal, mode, template);

  ctx.ui.notify(`Drafted ${pipelineFile}`, "info");
  pi.sendUserMessage(buildKickoffPrompt(goal, template));
}

export default async function pipelineExtension(pi: ExtensionAPI): Promise<void> {
  pi.registerCommand("pipeline:auto", {
    description:
      "Seed .scratchpad/PIPELINE.md and run /skill:pipeline in dynamic mode (approval required before execution).",
    handler: async (args, ctx) => {
      await kickoffPipeline(pi, args, ctx);
    },
  });

  for (const template of await pipelineTemplates()) {
    pi.registerCommand(`pipeline:${template.name}`, {
      description: `${template.description} (seeds .scratchpad/PIPELINE.md then invokes /skill:pipeline)`,
      handler: async (args, ctx) => {
        await kickoffPipeline(pi, args, ctx, template);
      },
    });
  }
}
