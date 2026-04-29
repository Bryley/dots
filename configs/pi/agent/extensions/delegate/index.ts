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

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";
import { DelegateConversationState, runPiExternally } from "./external";

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

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
            state.applyEvent(event);
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

      const taskName = theme.fg("accent", details.taskParams.id);
      const taskSuffix = theme.fg("dim", ` [${details.taskParams.power}]`);
      lines.push(`${taskMarker} ${taskName} ${taskSuffix}`);

      const snapshot = details.taskState.getStatus(!options.expanded);

      if (snapshot.hiddenCount > 0 && !options.expanded) {
        lines.push(`  ${theme.fg("dim", `+ ${snapshot.hiddenCount} more`)}`);
        lines.push(`  ${theme.fg("dim", "Press Ctrl+O for more")}`);
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
