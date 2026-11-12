import { spawn, type ChildProcess } from "node:child_process";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// Keeps the Mac from idle sleeping while the agent is working, so runs survive a locked screen.
export default function (pi: ExtensionAPI) {
  let caf: ChildProcess | undefined;

  const stop = () => {
    caf?.kill();
    caf = undefined;
  };

  pi.on("agent_start", () => {
    if (caf || process.platform !== "darwin") return;
    // -w ties caffeinate to pi's pid, so it also exits if pi crashes
    caf = spawn("caffeinate", ["-i", "-w", String(process.pid)], { stdio: "ignore" });
    caf.on("exit", () => {
      caf = undefined;
    });
  });

  // agent_end can be followed by retries or queued messages; agent_settled means truly idle
  pi.on("agent_settled", stop);
  pi.on("session_shutdown", stop);
}
