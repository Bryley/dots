import { spawn } from "node:child_process";
import { mkdirSync } from "node:fs";
import { resolve as resolvePath } from "node:path";
import { cwd as getCwd, env } from "node:process";

type PiMessageContent =
  | { type: "text"; text: string }
  | { type: "thinking"; thinking: string; thinkingSignature?: string }
  | {
    type: "toolCall";
    toolCallId: string;
    toolName: string;
    args: Record<string, unknown>;
  }
  | Record<string, unknown>;

type PiMessage = {
  role: "user" | "assistant" | "toolResult";
  content: PiMessageContent[];
  timestamp?: number;
  stopReason?: string;
} & Record<string, unknown>;

type ToolCallId = string;

type PiAssistantMessageEvent = {
  type:
  | "thinking_start"
  | "thinking_delta"
  | "thinking_end"
  | "text_start"
  | "text_delta"
  | "text_end"
  | "toolcall_start"
  | "toolcall_delta"
  | "toolcall_end";
  delta?: string;
  content?: string;
  partial?: Record<string, unknown>;
  contentIndex?: number;
} & Record<string, unknown>;

export type PiJsonLine =
  | {
    type: "session";
    version: number;
    id: string;
    timestamp: string;
    cwd: string;
  }
  | { type: "agent_start" }
  | { type: "agent_end"; messages: PiMessage[] }
  | { type: "turn_start" }
  | { type: "turn_end"; message: PiMessage; toolResults: unknown[] }
  | { type: "message_start"; message: PiMessage }
  | {
    type: "message_update";
    message: PiMessage;
    assistantMessageEvent: PiAssistantMessageEvent;
  }
  | { type: "message_end"; message: PiMessage }
  | {
    type: "tool_execution_start";
    toolCallId: ToolCallId;
    toolName: string;
    args: Record<string, unknown>;
  }
  | {
    type: "tool_execution_update";
    toolCallId: ToolCallId;
    toolName: string;
    args: Record<string, unknown>;
    partialResult: Record<string, unknown>;
  }
  | {
    type: "tool_execution_end";
    toolCallId: ToolCallId;
    toolName: string;
    result: Record<string, unknown>;
    isError: boolean;
  };

export type StatusObject = {
  status: "pending" | "done" | "failed";
  text: string;
};

export type StatusSnapshot = {
  statuses: StatusObject[];
  hiddenCount: number;
  total: number;
};

export class DelegateConversationState {
  private response = "";
  private toolCalls: Record<ToolCallId, string> = {};
  private interactions: StatusObject[] = [];
  private thinking = false;
  private writing = false;

  applyEvent(event: PiJsonLine): void {
    if (event.type === "message_update") {
      if (event.assistantMessageEvent.type === "thinking_start") {
        this.thinking = true;
        return;
      }
      if (event.assistantMessageEvent.type === "thinking_end") {
        if (this.thinking)
          this.interactions.push({ status: "done", text: "thinking..." });
        this.thinking = false;
        return;
      }
      if (event.assistantMessageEvent.type === "text_start") {
        this.writing = true;
        return;
      }
      if (event.assistantMessageEvent.type === "text_end") {
        if (this.writing)
          this.interactions.push({
            status: "done",
            text: "writing response...",
          });
        this.writing = false;
        return;
      }
      if (event.assistantMessageEvent.type === "text_delta") {
        const delta = event.assistantMessageEvent.delta;
        if (delta) this.response += delta;
      }
      return;
    }

    if (event.type === "tool_execution_start") {
      this.toolCalls[event.toolCallId] = this.formatToolInteraction(
        event.toolName,
        event.args,
      );
      return;
    }

    if (event.type === "tool_execution_end") {
      const tool =
        this.toolCalls[event.toolCallId] ??
        this.formatToolInteraction(event.toolName);
      delete this.toolCalls[event.toolCallId];

      this.interactions.push({
        status: event.isError ? "failed" : "done",
        text: tool,
      });
      return;
    }
  }

  getStatus(compressed: boolean = true): StatusSnapshot {
    const all: StatusObject[] = [...this.interactions];

    for (const tool of Object.values(this.toolCalls)) {
      all.push({ status: "pending", text: tool });
    }

    if (this.thinking) all.push({ status: "pending", text: "thinking..." });
    if (this.writing) all.push({ status: "pending", text: "writing response..." });

    if (!compressed) {
      return { statuses: all, hiddenCount: 0, total: all.length };
    }

    const tailSize = 5;
    const hiddenCount = Math.max(all.length - tailSize, 0);
    return {
      statuses: all.slice(-tailSize),
      hiddenCount,
      total: all.length,
    };
  }

  getResponse(): string {
    return this.response;
  }

  private formatToolInteraction(
    toolName: string,
    args?: Record<string, unknown>,
  ): string {
    if (toolName === "bash") {
      const command = String(args?.command ?? "").replace(/\r?\n/g, " ↩ ");
      const truncated = command.length > 32 ? `${command.slice(0, 32)}...` : command;
      return `$ ${truncated}`;
    }
    if (toolName === "read") return `read ${String(args?.path ?? "")}`;
    if (toolName === "write") return `write ${String(args?.path ?? "")}`;
    if (toolName === "edit") return `edit ${String(args?.path ?? "")}`;
    return `${toolName}...`;
  }
}

export type DelegatePower = "light" | "versatile" | "powerful";

export type RunPiExternalOptions = {
  id?: string;
  power?: DelegatePower;
};

const POWER_TO_MODEL: Record<DelegatePower, string> = {
  light: "openai-codex/gpt-5.4-mini:medium",
  versatile: "openai-codex/gpt-5.3-codex:medium",
  powerful: "openai-codex/gpt-5.3-codex:high",
};

export async function runPiExternally(
  prompt: string,
  options?: RunPiExternalOptions,
  onEvent?: (event: PiJsonLine) => void,
  signal?: AbortSignal,
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  return await new Promise((resolve, reject) => {
    const args = ["--mode", "json", "-p"];

    const power = options?.power;
    if (power) {
      args.push("--model", POWER_TO_MODEL[power]);
    }

    args.push(prompt);

    const delegateCwd = resolvePath(getCwd(), ".scratchpad/delegate-workspace");
    mkdirSync(delegateCwd, { recursive: true });

    const child = spawn("pi", args, {
      cwd: delegateCwd,
      stdio: ["ignore", "pipe", "pipe"],
      env,
    });

    let stdout = "";
    let stderr = "";
    let buffer = "";

    const onAbort = () => child.kill("SIGTERM");
    signal?.addEventListener("abort", onAbort);

    child.stdout.on("data", (chunk: Buffer) => {
      const text = chunk.toString("utf8");
      stdout += text;
      buffer += text;

      let idx = buffer.indexOf("\n");
      while (idx !== -1) {
        const line = buffer.slice(0, idx).trim();
        buffer = buffer.slice(idx + 1);

        if (line) {
          try {
            onEvent?.(JSON.parse(line) as PiJsonLine);
          } catch {
            // ignore non-JSON lines
          }
        }

        idx = buffer.indexOf("\n");
      }
    });

    child.stderr.on("data", (chunk: Buffer) => {
      stderr += chunk.toString("utf8");
    });

    child.on("error", (err) => {
      signal?.removeEventListener("abort", onAbort);
      reject(err);
    });

    child.on("close", (code) => {
      signal?.removeEventListener("abort", onAbort);
      resolve({ stdout, stderr, exitCode: code ?? 1 });
    });
  });
}
