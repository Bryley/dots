/**
 * A custom built extension for basic safety, checking before running dangerous
 * commands and preventing reading of secret files like .env files.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { basename, resolve } from "node:path";

const BLOCKED_FILE_NAMES: RegExp[] = [/\.*.env.*/, /.*secret\..*/];

const DANGEROUS_BASH_PATTERNS: RegExp[] = [
  /\brm\s+-rf\b/,
  /\bsudo\b/,
  /\bmkfs\b/,
  /\bdd\b.*\bof=\/dev\//,
  /\bshutdown\b|\breboot\b|\bpoweroff\b/,
  /\bchown\s+-R\b/,
  /\bchmod\s+(-R\s+)?777\b/,
  /\bcurl\b.*\|\s*(sh|bash|zsh)\b/,
  /\bwget\b.*\|\s*(sh|bash|zsh)\b/,
];

function isPathBlocked(workingDir: string, path: string): boolean {
  let abs = resolve(workingDir, path);
  let name = basename(abs);
  return BLOCKED_FILE_NAMES.some((regexp) => regexp.test(name));
}

function isCommandDangerous(cmd: string): boolean {
  return DANGEROUS_BASH_PATTERNS.some((regexp) => regexp.test(cmd));
}

export default function(pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (isToolCallEventType("read", event)) {
      if (isPathBlocked(ctx.cwd, event.input.path)) {
        return {
          block: true,
          reason: `Reading file '${event.input.path}' is blocked by the safety-gate extension`,
        };
      }
    } else if (isToolCallEventType("bash", event)) {
      let cmd = event.input.command;

      if (!isCommandDangerous(event.input.command)) return;

      // Non-interactive mode: safest default is block
      if (!ctx.hasUI) {
        return {
          block: true,
          reason: "Dangerous bash blocked (no UI available for confirmation).",
        };
      }

      const ok = await ctx.ui.confirm(
        "Potentially dangerous command",
        `Allow this command?\n\n${cmd}`,
      );

      if (!ok) {
        return {
          block: true,
          reason: "User denied potentially dangerous bash command.",
        };
      }
    }
  });
}
