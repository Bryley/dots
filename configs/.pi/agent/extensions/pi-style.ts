import { VERSION, type ExtensionAPI, type SourceInfo, type Theme } from "@mariozechner/pi-coding-agent";
import { basename, dirname } from "node:path";

const PI_LOGO = ["██████", "██  ██", "████  ██", "██    ██"] as const;

type ResourceItem = {
  name: string;
  installed: boolean;
};

type ResourceSnapshot = {
  extensions: ResourceItem[];
  skills: ResourceItem[];
};

function isLightTheme(theme: Theme): boolean {
  return (theme.name ?? "").toLowerCase().includes("light");
}

function getCustomName(path: string): string {
  const file = basename(path);
  if (file === "SKILL.md" || file === "index.ts" || file === "index.js") {
    return basename(dirname(path));
  }
  return file.replace(/\.(ts|js|md)$/i, "");
}

function getInstalledName(sourceInfo: SourceInfo): string {
  return sourceInfo.source.replace(/^(npm:|git:)/, "");
}

function getSkillName(path: string): string {
  const file = basename(path);
  if (file === "SKILL.md") return basename(dirname(path));
  return getCustomName(path);
}

function extractResourceItem(sourceInfo: SourceInfo, kind: "extension" | "skill"): ResourceItem | undefined {
  const path = sourceInfo.path ?? "";
  if (!path || path.startsWith("<")) return undefined;

  const installed = sourceInfo.origin === "package";
  const pkg = getInstalledName(sourceInfo);

  if (kind === "skill") {
    const skill = getSkillName(path);
    return {
      name: installed ? `${pkg}:${skill}` : skill,
      installed,
    };
  }

  return {
    name: installed ? pkg : getCustomName(path),
    installed,
  };
}

function dedupeAndSort(items: ResourceItem[]): ResourceItem[] {
  const byKey = new Map<string, ResourceItem>();
  for (const item of items) {
    const key = `${item.installed ? "pkg" : "custom"}:${item.name}`;
    if (!byKey.has(key)) byKey.set(key, item);
  }

  return [...byKey.values()].sort((a, b) => a.name.localeCompare(b.name));
}

function collectResources(pi: ExtensionAPI): ResourceSnapshot {
  const commandSources = pi
    .getCommands()
    .map((cmd) => ({ source: cmd.source, sourceInfo: cmd.sourceInfo }));

  const toolSources = pi.getAllTools().map((tool) => ({ source: "extension" as const, sourceInfo: tool.sourceInfo }));

  const extensionItems = [
    ...commandSources.filter((x) => x.source === "extension").map((x) => extractResourceItem(x.sourceInfo, "extension")),
    ...toolSources.map((x) => extractResourceItem(x.sourceInfo, "extension")),
  ].filter((x): x is ResourceItem => Boolean(x));

  const skillItems = commandSources
    .filter((x) => x.source === "skill")
    .map((x) => extractResourceItem(x.sourceInfo, "skill"))
    .filter((x): x is ResourceItem => Boolean(x));

  return {
    extensions: dedupeAndSort(extensionItems),
    skills: dedupeAndSort(skillItems),
  };
}

function formatResourceList(label: string, items: ResourceItem[], theme: Theme, logoColor: "text" | "dim"): string {
  const installedColor = isLightTheme(theme) ? "accent" : "accent";

  if (items.length === 0) {
    return theme.fg("muted", ` ${label}: none`);
  }

  const content = items
    .map((item) => {
      const color = item.installed ? installedColor : logoColor;
      return theme.fg(color, item.name);
    })
    .join(theme.fg("muted", ", "));

  return `${theme.fg("muted", ` ${label}: `)}${content}`;
}

function getHeaderLines(theme: Theme, resources: ResourceSnapshot): string[] {
  const logoColor = isLightTheme(theme) ? "dim" : "text";

  const harnessText = "Pi Agent Harness";
  const versionText = `v${VERSION}`;

  const line1 = PI_LOGO[0];
  const line2 = `${PI_LOGO[1]}    ${harnessText}`;

  // Keep version right-aligned to the same width as line 2
  const width = Math.max(line1.length, line2.length);
  const line3Padding = Math.max(1, width - PI_LOGO[2].length - versionText.length);
  const line3 = `${PI_LOGO[2]}${" ".repeat(line3Padding)}${versionText}`;
  const line4 = PI_LOGO[3];

  const inner = [line1, line2, line3, line4].map((line) => ` ${line.padEnd(width, " ")} `);
  const blank = " ".repeat(width + 2);

  const logoBlock = [blank, ...inner, blank].map((line) => theme.fg(logoColor, ` ${line}`));

  return [
    ...logoBlock,
    "",
    formatResourceList("Extensions", resources.extensions, theme, logoColor),
    formatResourceList("Skills", resources.skills, theme, logoColor),
  ];
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    const resources = collectResources(pi);

    ctx.ui.setHeader((_tui, theme) => ({
      render(_width: number): string[] {
        return ["", ...getHeaderLines(theme, resources), ""];
      },
      invalidate() {},
    }));
  });
}
