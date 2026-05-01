/**
 * This is my custom setup for sub-agents.
 *
 * Intended flow (simple):
 * - I talk to one main orchestrator agent.
 * - The orchestrator chooses a power class for each delegated task
 *   (light, versatile, or powerful).
 * - Each delegated task runs in a fresh context as a separate sub-agent.
 * - The delegate tool streams progress back, then returns results to the
 *   orchestrator so it can decide next steps.
 */


// TODO IDEAS:
// - [ ] Live view of what is inside delegated tasks is broken, would love to
//       fix but might be too much work.
// - [ ] Encourage the orchestrator to delegate tasks more somehow (without
//       passing the suggestion into the children processes)
// - [ ] Maybe add system prompt more "Agent like" into the delegated tasks to
//       make outputs more consistent.
// - [ ] Provide way for orchestrator to respond to questions asked by the
//       delegated tasks or pass them up to the user to answer (maybe provide
//       special tool for children processes that send the question to the
//       orchestrator or something).
//  - [ ] Rename "power" to "category" or "class"

import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";
import {
  DelegateConversationState,
  GLOBAL_TASK_TO_SESSION,
  runPiExternally,
} from "./external";

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

function formatTokens(value: number): string {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}k`;
  return String(value);
}

type Details = {
  spinner: string;
  taskParams: {
    id: string;
    task: string;
    power: "light" | "versatile" | "powerful";
  };
  taskState: DelegateConversationState;
  exitCode: number | undefined;
};

export default function(pi: ExtensionAPI) {
  pi.registerCommand("task", {
    description: "Read detailed delegated task's session logs",
    getArgumentCompletions(_argumentPrefix) {
      return Object.keys(GLOBAL_TASK_TO_SESSION).map((taskId) => {
        return {
          label: taskId,
          value: taskId,
        };
      });
    },
    async handler(args, ctx) {
      const session = GLOBAL_TASK_TO_SESSION[args];

      if (!session) {
        ctx.ui.notify(`Couldn't find session for task '${args}'`, "error");
        return;
      }

      const command = `cd ${JSON.stringify(session.cwd)} ; pi --session ${session.sessionId}`;
      spawnSync(
        "bash",
        [
          "-lc",
          "if command -v wl-copy >/dev/null 2>&1; then wl-copy; else pbcopy; fi",
        ],
        { input: command, encoding: "utf8" },
      );
      ctx.ui.notify(`Copied command for '${args}' to clipboard (note needs to be completed to work best)`, "info");
    },
  });

  pi.registerTool({
    name: "delegate",
    label: "Delegate",
    description: "Delegate tasks to fresh external pi runs",
    parameters: Type.Object({
      id: Type.String({
        description: "User-readable kebab-case task id (e.g. research-chairs)",
        pattern: "^[a-z0-9]+(?:-[a-z0-9]+)*$",
      }),
      task: Type.String({
        description:
          "Clear instruction prompt for the delegated agent to execute.",
      }),
      power: Type.Union(
        [
          Type.Literal("light"),
          Type.Literal("versatile"),
          Type.Literal("powerful"),
        ],
        {
          description:
            "Required model tier. Use light for straightforward, low-risk tasks with limited reasoning; versatile for most normal tasks; powerful for complex reasoning, ambiguity, or long multi-step work.",
        },
      ),
    }),

    async execute(_toolCallId, params, signal, onUpdate) {
      const state = new DelegateConversationState();
      let spinnerIndex = 0;
      let exitCode: number | undefined = undefined;

      const getDetails = () => {
        return {
          spinner: SPINNER_FRAMES[spinnerIndex],
          taskParams: params,
          taskState: state,
          exitCode: exitCode,
        } as Details;
      };

      const pushUpdate = () => {
        onUpdate?.({
          content: [{ type: "text", text: "Delegating..." }],
          details: getDetails(),
        });
      };
      const spinnerTimer = setInterval(() => {
        spinnerIndex = (spinnerIndex + 1) % SPINNER_FRAMES.length;
        pushUpdate();
      }, 100);

      try {
        const delegate = await runPiExternally(
          params.task,
          {
            id: params.id,
            power: params.power,
          },
          (event) => {
            state.applyEvent(params.id, event);
            pushUpdate();
          },
          signal,
        );
        exitCode = delegate.exitCode;
      } finally {
        clearInterval(spinnerTimer);
      }

      return {
        content: [{ type: "text", text: state.getResponse() || "(no output)" }],
        details: getDetails(),
      };
    },

    renderResult(result, options, theme, _context) {
      const details = (result.details ?? {}) as Details;
      const lines: string[] = [];

      const SPINNER_MARKER = theme.fg("accent", details.spinner);
      const SUCCESS_MARKER = theme.fg("success", "✓");
      const ERROR_MARKER = theme.fg("error", "✗");

      let taskMarker = "";
      switch (details.exitCode) {
        case undefined:
          taskMarker = SPINNER_MARKER;
          break;
        case 0:
          taskMarker = SUCCESS_MARKER;
          break;
        default:
          taskMarker = ERROR_MARKER;
      }

      const snapshot = details.taskState.getStatus(!options.expanded);

      const taskName = theme.fg("accent", details.taskParams.id);
      const taskPower = theme.fg("dim", `[${details.taskParams.power}]`);
      const taskUsage = theme.fg(
        "dim",
        `💰$${snapshot.usage.costUsd.toFixed(4)} 🧠 ${formatTokens(
          snapshot.usage.contextTokens,
        )}`,
      );
      lines.push(`${taskMarker} ${taskName} ${taskPower} ${taskUsage}`);

      if (snapshot.hiddenCount > 0 && !options.expanded) {
        lines.push(
          theme.fg(
            "dim",
            `  ... (${snapshot.hiddenCount} more lines, ctrl+o to expand)`,
          ),
        );
      }

      for (const status of snapshot.statuses) {
        if (status.status === "done") {
          lines.push(`  ${SUCCESS_MARKER} ${status.text}`);
        } else if (status.status === "failed") {
          lines.push(`  ${ERROR_MARKER} ${status.text}`);
        } else {
          lines.push(`  ${SPINNER_MARKER} ${theme.fg("muted", status.text)}`);
        }
      }

      const inputOutputLength = options.expanded ? 2040 : 128;

      lines.push("");
      let prompt = details.taskParams.task;
      prompt = options.expanded
        ? prompt
        : String(prompt).replace(/\r?\n/g, " ↩ ");
      prompt =
        prompt.length > inputOutputLength
          ? `${prompt.slice(0, inputOutputLength)}...`
          : prompt;
      lines.push(theme.fg("dim", prompt));

      let response = details.taskState.getResponse();

      if (response) {
        lines.push(theme.fg("dim", theme.bold("---")));
        response = options.expanded
          ? response
          : String(response).replace(/\r?\n/g, " ↩ ");
        response =
          response.length > inputOutputLength
            ? `${response.slice(0, inputOutputLength)}...`
            : response;
        lines.push(theme.fg("text", response));
      }

      return new Text(lines.join("\n"), 0, 0);
    },
  });
}
