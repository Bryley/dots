import { exec } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const execAsync = promisify(exec);
const POLL_MS = 2000;

type ThemeName = "dark" | "light";

async function detectMacTheme(): Promise<ThemeName> {
  const { stdout } = await execAsync(
    "osascript -e 'tell application \"System Events\" to tell appearance preferences to return dark mode'",
  );
  return stdout.trim() === "true" ? "dark" : "light";
}

async function detectLinuxTheme(): Promise<ThemeName> {
  const { stdout } = await execAsync(`bash -lc '
# 1) XDG portal (works on many Wayland setups incl. niri when portal is configured)
if command -v gdbus >/dev/null 2>&1; then
  v=$(gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.portal.Settings.Read \
    org.freedesktop.appearance color-scheme 2>/dev/null || true)
  case "$v" in
    *"uint32 1"*) echo dark; exit 0 ;;
    *"uint32 2"*) echo light; exit 0 ;;
  esac
fi

# 2) GNOME
if command -v gsettings >/dev/null 2>&1; then
  cs=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
  case "$cs" in *prefer-dark*) echo dark; exit 0 ;; esac
  gtk=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)
  case "$gtk" in *-dark*|*Dark*) echo dark; exit 0 ;; esac
  echo light; exit 0
fi

# 3) KDE
if command -v kreadconfig6 >/dev/null 2>&1; then
  s=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)
  case "$s" in *[Dd]ark*) echo dark ;; *) echo light ;; esac
  exit 0
fi
if command -v kreadconfig5 >/dev/null 2>&1; then
  s=$(kreadconfig5 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)
  case "$s" in *[Dd]ark*) echo dark ;; *) echo light ;; esac
  exit 0
fi

echo light
'`);

  return stdout.trim() === "dark" ? "dark" : "light";
}

async function detectTheme(): Promise<ThemeName> {
  try {
    if (process.platform === "darwin") return await detectMacTheme();
    if (process.platform === "linux") return await detectLinuxTheme();
  } catch {
    // ignore
  }
  return "dark";
}

export default function (pi: ExtensionAPI) {
  let timer: ReturnType<typeof setInterval> | null = null;
  let current: ThemeName | null = null;

  pi.on("session_start", async (_event, ctx) => {
    const apply = async () => {
      const next = await detectTheme();
      if (next !== current) {
        current = next;
        ctx.ui.setTheme(next);
      }
    };

    await apply();
    timer = setInterval(() => void apply(), POLL_MS);
  });

  pi.on("session_shutdown", () => {
    if (timer) clearInterval(timer);
    timer = null;
    current = null;
  });
}
