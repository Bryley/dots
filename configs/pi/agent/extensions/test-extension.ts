import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Box, Text } from "@mariozechner/pi-tui";
import { Type } from "typebox";

export default function(pi: ExtensionAPI) {
  pi.registerMessageRenderer("my-test", (message, options, theme) => {
    return new Text(`Good day! ${JSON.stringify(message.details)}`, 0, 0);
  });

  pi.registerCommand("test", {
    handler: async (args, ctx) => {
      pi.sendMessage({
        customType: "my-test",
        content: "This is just a test custom message",
        display: true,
        details: { extraData: 42 },
      });
    },
  });

  // pi.registerTool({
  //   name: "delegate",
  //   label: "Delegate",
  //   description: "Run delegated tasks",
  //   parameters: Type.Object({
  //     tasks: Type.Array(Type.Object({ task: Type.String() })),
  //   }),
  //
  //   async execute(_id, params, _signal, onUpdate) {
  //     for (let i = 0; i < params.tasks.length; i++) {
  //       onUpdate?.({
  //         content: [
  //           {
  //             type: "text",
  //             text: `Running ${i + 1}/${params.tasks.length}: ${params.tasks[i].task
  //               }`,
  //           },
  //         ],
  //         details: { step: i + 1, total: params.tasks.length },
  //       });
  //       await new Promise((r) => setTimeout(r, 300));
  //     }
  //     return {
  //       content: [{ type: "text", text: "Delegate complete." }],
  //       details: {},
  //     };
  //   },
  //
  //   renderCall(args, theme) {
  //     const count = args.tasks?.length ?? 0;
  //     const first = args.tasks?.[0]?.task ?? "";
  //     const badge = theme.fg("accent", "▣");
  //     const title = theme.fg("toolTitle", theme.bold(" Planning Lead"));
  //     const subtitle = theme.fg(
  //       "muted",
  //       ` ${count} task${count === 1 ? "" : "s"}`,
  //     );
  //     const body = theme.fg(
  //       "dim",
  //       `│ ${first.slice(0, 80)}${first.length > 80 ? "..." : ""}`,
  //     );
  //     return new Text(`${badge}${title}${subtitle}\n${body}`, 0, 0);
  //   },
  //
  //   renderResult(result, { isPartial }, theme, context) {
  //     const textPart = result.content.find((c: any) => c.type === "text") as
  //       | { text?: string }
  //       | undefined;
  //     const line = textPart?.text ?? "";
  //
  //     const isError = context.isError;
  //     const bg = isPartial
  //       ? "toolPendingBg" // gray-ish
  //       : isError
  //         ? "toolErrorBg" // red-ish
  //         : "toolSuccessBg"; // green-ish
  //
  //     const color = isPartial ? "muted" : isError ? "error" : "success";
  //     const prefix = isPartial ? "● " : isError ? "✗ " : "✓ ";
  //
  //     const box = new Box(1, 0, (s) => theme.bg(bg, s));
  //     box.addChild(new Text(theme.fg(color, prefix + line), 0, 0));
  //     return box;
  //   },
  // });
}
