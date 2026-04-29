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

// TODO NTS: Work on cleaning up this code, moving the generated code to
// another file, also fixing the response output to just be the response. Then
// also need to support multiple parallel tasks and better output (read, bash,
// write count, token count, estimated cost of each agent). Extra params, max
// turns, model, id and so on.

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";
import {
  DelegateConversationState,
  runPiExternally,
  type DelegatePower,
  type StatusObject,
} from "./external";

export default function(pi: ExtensionAPI) {
  pi.registerTool({
    name: "delegate",
    label: "Delegate",
    description: "Delegate tasks to fresh external pi runs",
    parameters: Type.Object({
      tasks: Type.Array(
        Type.Object({
          id: Type.String({
            description:
              "User-readable kebab-case task id (e.g. research-chairs)",
            pattern: "^[a-z0-9]+(?:-[a-z0-9]+)*$",
          }),
          task: Type.String({
            description: "Clear instruction for the delegated agent to execute.",
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
      ),
    }),
    async execute(_toolCallId, params, signal, onUpdate) {
      const tasks = params.tasks ?? [];
      if (tasks.length === 0) {
        return {
          content: [{ type: "text", text: "No tasks provided." }],
          details: {},
        };
      }

      const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
      let spinnerIndex = 0;

      const normalizePower = (
        power: "light" | "versatile" | "powerful" | undefined,
      ): DelegatePower => {
        return power ?? "versatile";
      };

      const states: Record<string, DelegateConversationState> = {};
      const exitCodes: Record<string, number | undefined> = {};
      const responses: Record<string, string> = {};

      for (const task of tasks) {
        states[task.id] = new DelegateConversationState();
      }

      const pushUpdates = () => {
        onUpdate?.({
          content: [{ type: "text", text: "Delegating..." }],
          details: {
            spinnerFrame: spinnerFrames[spinnerIndex],
            tasks: tasks.map((task) => {
              const compact = states[task.id]?.getStatus(true);
              const full = states[task.id]?.getStatus(false);
              return {
                id: task.id,
                power: normalizePower(task.power),
                statuses: compact?.statuses ?? [],
                allStatuses: full?.statuses ?? [],
                hiddenCount: compact?.hiddenCount ?? 0,
                exitCode: exitCodes[task.id],
                hasResponse: Boolean(states[task.id]?.getResponse()?.trim()),
              };
            }),
          },
        });
      };

      const spinnerTimer = setInterval(() => {
        spinnerIndex = (spinnerIndex + 1) % spinnerFrames.length;
        pushUpdates();
      }, 100);

      const delegatedRuns = tasks.map(async (task) => {
        const delegated = await runPiExternally(
          task.task,
          {
            id: task.id,
            power: normalizePower(task.power),
          },
          (event) => {
            states[task.id]?.applyEvent(event);
            pushUpdates();
          },
          signal,
        );

        exitCodes[task.id] = delegated.exitCode;
        responses[task.id] =
          states[task.id]?.getResponse() ||
          delegated.stdout ||
          delegated.stderr ||
          "(no output)";
      });

      try {
        await Promise.all(delegatedRuns);
      } finally {
        clearInterval(spinnerTimer);
      }

      const finalText = tasks
        .map((task) => `# ${task.id}\n${responses[task.id] ?? "(no output)"}`)
        .join("\n\n");

      return {
        content: [{ type: "text", text: finalText }],
        details: {
          spinnerFrame: spinnerFrames[spinnerIndex],
          tasks: tasks.map((task) => {
            const compact = states[task.id]?.getStatus(true);
            const full = states[task.id]?.getStatus(false);
            return {
              id: task.id,
              power: normalizePower(task.power),
              statuses: compact?.statuses ?? [],
              allStatuses: full?.statuses ?? [],
              hiddenCount: compact?.hiddenCount ?? 0,
              exitCode: exitCodes[task.id],
              hasResponse: Boolean((responses[task.id] ?? "").trim()),
            };
          }),
        },
      };
    },

    renderCall(args, theme, context) {
      const tasksLength = context.args.tasks.length;

      const title = `${theme.fg(
        "toolTitle",
        theme.bold("delegate"),
      )} ${tasksLength} task${tasksLength > 1 ? "s" : ""}`;

      return new Text(title, 0, 0);
    },

    renderResult(result, options, theme, _context) {
      const details = (result.details ?? {}) as {
        spinnerFrame?: string;
        tasks?: Array<{
          id: string;
          power?: DelegatePower;
          statuses: StatusObject[];
          allStatuses?: StatusObject[];
          hiddenCount?: number;
          exitCode?: number;
          hasResponse?: boolean;
        }>;
      };

      const tasks = details.tasks ?? [];
      if (tasks.length === 0) {
        const text = result.content.find((c) => c.type === "text");
        return new Text(text?.type === "text" ? text.text : "", 0, 0);
      }

      const spinner = options.isPartial ? details.spinnerFrame ?? "…" : "…";
      const lines: string[] = [];

      for (const task of tasks) {
        const hasPending = task.exitCode === undefined;
        const agentFailed = task.exitCode !== undefined && task.exitCode !== 0 && !task.hasResponse;

        const marker = hasPending
          ? theme.fg("accent", spinner)
          : agentFailed
            ? theme.fg("error", "✗")
            : theme.fg("success", "✓");

        const suffix = task.power ? theme.fg("dim", ` (${task.power})`) : "";
        lines.push(`${marker} ${theme.fg("accent", task.id)}${suffix}`);

        const shownStatuses = options.expanded
          ? (task.allStatuses ?? task.statuses)
          : task.statuses;

        if (!options.expanded && (task.hiddenCount ?? 0) > 0) {
          lines.push(`  ${theme.fg("dim", `+ ${task.hiddenCount} more`)}`);
          lines.push(`  ${theme.fg("dim", "Press Ctrl+O for more")}`);
        }

        for (const item of shownStatuses) {
          if (item.status === "done") {
            lines.push(`  ${theme.fg("success", "✓")} ${item.text}`);
          } else if (item.status === "failed") {
            lines.push(`  ${theme.fg("error", "✗")} ${item.text}`);
          } else {
            lines.push(
              `  ${theme.fg("accent", spinner)} ${theme.fg(
                "muted",
                item.text,
              )}`,
            );
          }
        }
      }

      return new Text(lines.join("\n"), 0, 0);
    },
  });
}
