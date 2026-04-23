#!/usr/bin/env node

/**
 * Screenshot utility for design-build skill.
 *
 * Usage examples:
 *   node scripts/screenshot.js --file ./prototype/index.html
 *   node scripts/screenshot.js --file ./prototype/index.html --selector "[data-ai-id='hero']"
 *   node scripts/screenshot.js --url http://localhost:4173 --out ./prototype/.shots/home.png
 *
 * Behavior:
 * - If --selector is omitted, captures the full page height (clipped to viewport width by default).
 * - If --out is omitted, writes to a temp file and prints that absolute path to stdout.
 */

const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { execSync } = require("node:child_process");
const { pathToFileURL } = require("node:url");

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;
    const key = token.slice(2);

    // Boolean flags
    if (["help", "scroll-through", "debug-dimensions"].includes(key)) {
      args[key] = true;
      continue;
    }

    const next = argv[i + 1];
    if (!next || next.startsWith("--")) {
      args[key] = true;
      continue;
    }

    args[key] = next;
    i++;
  }
  return args;
}

function parseBooleanArg(value, defaultValue) {
  if (value === undefined || value === null) return defaultValue;
  if (typeof value === "boolean") return value;
  const normalized = String(value).trim().toLowerCase();
  if (["1", "true", "yes", "y", "on"].includes(normalized)) return true;
  if (["0", "false", "no", "n", "off"].includes(normalized)) return false;
  return defaultValue;
}

function printHelp() {
  console.error(`
Usage:
  screenshot.js [--file <path> | --url <url>] [options]

Options:
  --file <path>             Local HTML file path (default: ./prototype/index.html if present)
  --url <url>               URL to capture (http://..., https://..., file://...)
  --selector <css>          Optional CSS selector. If omitted, captures page screenshot.
  --out <path>              Optional output path. If omitted, temp path is used and printed.
  --width <px>              Viewport width (default: 1440)
  --height <px>             Viewport height (default: 1024)
  --wait <ms>               Wait after load before capture (default: 300)
  --wait-for <css>          Wait until selector exists before capture
  --timeout <ms>            Timeout for navigation/waits (default: 15000)
  --full-page <bool>        Capture full-page height (default: true)
  --capture-width <mode>    full-page width mode: viewport | page (default: viewport)
  --max-height <px>         Max full-page capture height (default: 30000)
  --hide-overflow-x <bool>  Hide horizontal overflow before capture (default: true)
  --scroll-position <pos>   Scroll position before capture: top | bottom (default: top)
  --scroll-through          Scroll through page first (helps trigger lazy content)
  --debug-dimensions        Print page/viewport dimensions to stderr
  --help                    Show this help
`);
}

function ensureDirForFile(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function makeTempOutPath() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-design-shot-"));
  const filename = `shot-${Date.now()}.png`;
  return path.join(dir, filename);
}

function resolveCaptureTarget(args) {
  if (args.url && args.file) {
    throw new Error("Use either --url or --file, not both.");
  }

  if (args.url) return args.url;

  const fileArg = args.file || "./prototype/index.html";
  const abs = path.resolve(process.cwd(), fileArg);
  if (!fs.existsSync(abs)) {
    throw new Error(
      `Input file not found: ${abs}. Provide --file <path> or --url <url>.`
    );
  }
  return pathToFileURL(abs).href;
}

function loadPlaywright() {
  try {
    return require("playwright");
  } catch (_e) {
    // Fallback: resolve from globally pinned mise npm:playwright tool.
    try {
      const base = execSync("mise where npm:playwright", {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
      }).trim();

      if (base) {
        const candidateA = path.join(base, "node_modules", "playwright");
        const candidateB = path.join(base, "lib", "node_modules", "playwright");
        if (fs.existsSync(candidateA)) return require(candidateA);
        if (fs.existsSync(candidateB)) return require(candidateB);
      }
    } catch (_err) {
      // ignored; handled below with friendly error
    }
  }

  return null;
}

async function autoScrollPage(page) {
  await page.evaluate(async () => {
    await new Promise((resolve) => {
      const total = Math.max(
        document.documentElement.scrollHeight,
        document.body?.scrollHeight || 0
      );
      const step = Math.max(300, Math.floor(window.innerHeight * 0.75));
      let y = 0;

      const tick = () => {
        y += step;
        window.scrollTo(0, y);
        if (y + window.innerHeight >= total) {
          window.scrollTo(0, total);
          requestAnimationFrame(() => resolve());
          return;
        }
        requestAnimationFrame(tick);
      };

      tick();
    });
  });
}

async function getPageMetrics(page) {
  return page.evaluate(() => {
    const de = document.documentElement;
    const body = document.body;

    const pageWidth = Math.max(
      de?.scrollWidth || 0,
      body?.scrollWidth || 0,
      de?.offsetWidth || 0,
      body?.offsetWidth || 0,
      window.innerWidth
    );

    const pageHeight = Math.max(
      de?.scrollHeight || 0,
      body?.scrollHeight || 0,
      de?.offsetHeight || 0,
      body?.offsetHeight || 0,
      de?.clientHeight || 0,
      body?.clientHeight || 0,
      window.innerHeight
    );

    return {
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
      dpr: window.devicePixelRatio,
      pageWidth,
      pageHeight,
    };
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  const width = Number.parseInt(args.width, 10) || 1440;
  const height = Number.parseInt(args.height, 10) || 1024;
  const waitMs = Number.parseInt(args.wait, 10);
  const timeout = Number.parseInt(args.timeout, 10) || 15000;
  const selector = typeof args.selector === "string" ? args.selector : null;

  const fullPage = parseBooleanArg(args["full-page"], true);
  const hideOverflowX = parseBooleanArg(args["hide-overflow-x"], true);
  const captureWidthMode =
    args["capture-width"] === "page" ? "page" : "viewport";
  const scrollPosition =
    args["scroll-position"] === "bottom" ? "bottom" : "top";
  const maxHeight = Number.parseInt(args["max-height"], 10) || 30000;

  const outPath = args.out
    ? path.resolve(process.cwd(), String(args.out))
    : makeTempOutPath();
  ensureDirForFile(outPath);

  const target = resolveCaptureTarget(args);

  const playwright = loadPlaywright();
  if (!playwright) {
    console.error(
      "Missing dependency: playwright. Install with either:\n" +
        "  - mise use -g npm:playwright@<version>\n" +
        "  - or npm i -D playwright\n" +
        "Then install browser: playwright install chromium"
    );
    process.exit(1);
  }

  const { chromium } = playwright;

  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({ viewport: { width, height } });

    await page.goto(target, { waitUntil: "networkidle", timeout });

    if (typeof args["wait-for"] === "string") {
      await page.waitForSelector(args["wait-for"], { timeout });
    }

    if (hideOverflowX) {
      await page
        .addStyleTag({
          content: "html, body { overflow-x: hidden !important; }",
        })
        .catch(() => {});
    }

    if (args["scroll-through"]) {
      await autoScrollPage(page);
      await page.waitForTimeout(150);
    }

    if (scrollPosition === "bottom") {
      await page.evaluate(() => {
        window.scrollTo(0, Math.max(document.body?.scrollHeight || 0, document.documentElement.scrollHeight || 0));
      });
      await page.waitForTimeout(150);
    } else {
      await page.evaluate(() => window.scrollTo(0, 0));
    }

    if (Number.isFinite(waitMs) && waitMs > 0) {
      await page.waitForTimeout(waitMs);
    } else {
      await page.waitForTimeout(300);
    }

    if (selector) {
      const handle = await page.$(selector);
      if (!handle) {
        throw new Error(`Selector not found: ${selector}`);
      }
      await handle.screenshot({ path: outPath });
    } else if (!fullPage) {
      await page.screenshot({ path: outPath, fullPage: false });
    } else {
      const metrics = await getPageMetrics(page);

      if (args["debug-dimensions"]) {
        process.stderr.write(
          `[screenshot] viewport=${metrics.viewportWidth}x${metrics.viewportHeight} dpr=${metrics.dpr} page=${metrics.pageWidth}x${metrics.pageHeight}\n`
        );
      }

      if (captureWidthMode === "page") {
        await page.screenshot({ path: outPath, fullPage: true });
      } else {
        const targetWidth = Math.max(
          1,
          Math.floor(Math.min(metrics.viewportWidth, width, 32767))
        );
        const targetHeight = Math.max(
          1,
          Math.floor(Math.min(metrics.pageHeight, maxHeight, 32767))
        );

        await page.setViewportSize({ width: targetWidth, height: targetHeight });
        await page.evaluate(() => window.scrollTo(0, 0));
        await page.waitForTimeout(80);
        await page.screenshot({ path: outPath, fullPage: false });
      }
    }

    // Print ONLY the output path for easy tool piping.
    process.stdout.write(`${outPath}\n`);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err?.message || String(err));
  process.exit(1);
});
