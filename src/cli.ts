#!/usr/bin/env node
/**
 * Counter-Strike configs deploy CLI
 * Supports CS2, CSGO (legacy), and Counter-Strike: Source.
 * Symlink mode needs Administrator or Windows Developer Mode.
 */

import { spawnSync } from "node:child_process";
import {
  appendFileSync,
  copyFileSync,
  existsSync,
  lstatSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  readlinkSync,
  renameSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import * as p from "@clack/prompts";
import pc from "picocolors";

type GameKey = "cs2" | "csgo" | "css";
type DeployMode = "symlink" | "copy";

const VALID_GAMES: GameKey[] = ["cs2", "csgo", "css"];
const GAME_LABELS: Record<GameKey, string> = {
  cs2: "CS2  (Counter-Strike 2)",
  csgo: "CSGO (Counter-Strike: Global Offensive - legacy)",
  css: "CSS  (Counter-Strike: Source)",
};

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "..");

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

function parseArgs(argv: string[]): {
  mode: DeployMode | "";
  games: GameKey[] | "all" | "";
  elevatedLog: string;
} {
  let mode: DeployMode | "" = "";
  let games: GameKey[] | "all" | "" = "";
  let elevatedLog = "";

  const requireValue = (flag: string, next: string | undefined): string => {
    if (!next || next.startsWith("-")) {
      console.error(`Missing value for ${flag}. See --help for usage.`);
      process.exit(1);
    }
    return next;
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];

    if (arg === "--mode" || arg === "-m") {
      const value = requireValue(arg, next).toLowerCase();
      if (value !== "symlink" && value !== "copy") {
        console.error(`Invalid mode: '${next}'. Valid options: symlink, copy`);
        process.exit(1);
      }
      mode = value;
      i++;
      continue;
    }

    if (arg === "--game" || arg === "-g") {
      const value = requireValue(arg, next).toLowerCase();
      if (value === "all") {
        games = "all";
      } else {
        const parsed = value.split(",").map((g) => g.trim().toLowerCase());
        for (const g of parsed) {
          if (!VALID_GAMES.includes(g as GameKey)) {
            console.error(`Invalid game: '${g}'. Valid options: cs2, csgo, css, all`);
            process.exit(1);
          }
        }
        games = parsed as GameKey[];
      }
      i++;
      continue;
    }

    // Internal: elevated worker writes deploy output here for the parent terminal
    if (arg === "--elevated-log") {
      elevatedLog = requireValue(arg, next);
      i++;
      continue;
    }

    if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    }

    console.error(`Unknown argument: '${arg}'. See --help for usage.`);
    process.exit(1);
  }

  return { mode, games, elevatedLog };
}

function printHelp(): void {
  console.log(`
Usage: bun run dev -- [options]

Options:
  -g, --game <games>   cs2 | csgo | css | all | comma-separated (e.g. cs2,css)
  -m, --mode <mode>   symlink | copy
  -h, --help          Show this help

Examples:
  bun run dev
  bun run dev -- --game cs2 --mode copy
  bun run dev -- --game all --mode symlink
`);
}

// ---------------------------------------------------------------------------
// Steam library discovery
// ---------------------------------------------------------------------------

function getSteamPathFromRegistry(): string | null {
  if (process.platform !== "win32") return null;

  const result = spawnSync(
    "reg",
    ["query", "HKCU\\Software\\Valve\\Steam", "/v", "SteamPath"],
    { encoding: "utf8", windowsHide: true },
  );

  if (result.status !== 0 || !result.stdout) return null;

  const match = result.stdout.match(/SteamPath\s+REG_SZ\s+(.+)/i);
  if (!match) return null;

  return match[1].trim().replace(/\//g, "\\");
}

function getSteamLibraryRoots(): string[] {
  const roots: string[] = [];
  const steamPath = getSteamPathFromRegistry();

  if (steamPath && existsSync(steamPath)) {
    roots.push(steamPath);

    const vdfPath = join(steamPath, "steamapps", "libraryfolders.vdf");
    if (existsSync(vdfPath)) {
      const content = readFileSync(vdfPath, "utf8");
      for (const line of content.split(/\r?\n/)) {
        const match = line.match(/"path"\s+"([^"]+)"/);
        if (match) {
          roots.push(match[1].replace(/\\\\/g, "\\"));
        }
      }
    }
  }

  // Classic fallbacks
  roots.push("C:\\Program Files (x86)\\Steam");
  roots.push(join(homedir(), ".steam", "steam"));
  roots.push(join(homedir(), ".local", "share", "Steam"));

  return [...new Set(roots)];
}

function findFirstExisting(...relatives: string[]): string | null {
  for (const root of getSteamLibraryRoots()) {
    for (const relative of relatives) {
      const candidate = join(root, relative);
      if (existsSync(candidate)) return candidate;
    }
  }
  return null;
}

function findCfgPath(game: GameKey): string | null {
  switch (game) {
    case "cs2":
      return findFirstExisting(
        join("steamapps", "common", "Counter-Strike Global Offensive", "game", "csgo", "cfg"),
      );
    case "csgo":
      return findFirstExisting(
        join("steamapps", "common", "Counter-Strike Global Offensive", "csgo", "cfg"),
      );
    case "css":
      return findFirstExisting(
        join("steamapps", "common", "Counter-Strike Source", "cstrike", "cfg"),
      );
  }
}

// ---------------------------------------------------------------------------
// Elevation (Windows symlink mode)
// ---------------------------------------------------------------------------

function isElevated(): boolean {
  if (process.platform !== "win32") return process.getuid?.() === 0;

  const result = spawnSync(
    "powershell.exe",
    [
      "-NoProfile",
      "-Command",
      "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)",
    ],
    { encoding: "utf8", windowsHide: true },
  );

  return result.stdout.trim().toLowerCase() === "true";
}

function relaunchElevated(games: GameKey[], mode: DeployMode): boolean {
  const gameArg = games.join(",");
  const scriptPath = fileURLToPath(import.meta.url);
  const logPath = join(tmpdir(), `cs-configs-deploy-${process.pid}-${Date.now()}.log`);

  // Hidden elevated worker; output is mirrored back via --elevated-log
  const args = [
    scriptPath,
    "--mode",
    mode,
    "--game",
    gameArg,
    "--elevated-log",
    logPath,
  ];
  const argList = args.map((a) => `'${a.replace(/'/g, "''")}'`).join(", ");
  const workDir = repoRoot.replace(/'/g, "''");
  const exe = process.execPath.replace(/'/g, "''");
  const psCommand = [
    "try {",
    `  $p = Start-Process -FilePath '${exe}' -WorkingDirectory '${workDir}' -ArgumentList @(${argList}) -Verb RunAs -WindowStyle Hidden -Wait -PassThru;`,
    "  if ($null -eq $p) { exit 1 }",
    "  exit $p.ExitCode",
    "} catch {",
    "  exit 1",
    "}",
  ].join(" ");

  const result = spawnSync("powershell.exe", ["-NoProfile", "-Command", psCommand], {
    stdio: "ignore",
    windowsHide: true,
  });

  if (existsSync(logPath)) {
    try {
      const text = readFileSync(logPath, "utf8");
      if (text.trim()) process.stdout.write(text.endsWith("\n") ? text : `${text}\n`);
    } catch {
      // ignore log read failures
    }
    try {
      rmSync(logPath, { force: true });
    } catch {
      // ignore cleanup failures
    }
  }

  return result.status === 0;
}

function attachElevatedLog(logPath: string): void {
  writeFileSync(logPath, "", "utf8");

  const write = (...args: unknown[]) => {
    const line = args.map((a) => (typeof a === "string" ? a : String(a))).join(" ");
    try {
      appendFileSync(logPath, `${line}\n`, "utf8");
    } catch {
      // ignore log write failures
    }
  };

  const wrap =
    (fn: (...args: unknown[]) => void) =>
    (...args: unknown[]) => {
      write(...args);
      fn(...args);
    };

  console.log = wrap(console.log.bind(console));
  console.error = wrap(console.error.bind(console));
  console.warn = wrap(console.warn.bind(console));
  console.info = wrap(console.info.bind(console));
}

// ---------------------------------------------------------------------------
// Deploy helpers
// ---------------------------------------------------------------------------

function listCfgFiles(sourceDir: string): string[] {
  if (!existsSync(sourceDir)) return [];
  return readdirSync(sourceDir)
    .filter((name) => name.toLowerCase().endsWith(".cfg"))
    .sort();
}

function isSymlink(path: string): boolean {
  try {
    return lstatSync(path).isSymbolicLink();
  } catch {
    return false;
  }
}

function deployFile(
  sourcePath: string,
  targetPath: string,
  mode: DeployMode,
): { ok: boolean; message: string } {
  const fileName = sourcePath.split(/[/\\]/).pop()!;
  const backupPath = `${targetPath}.backup`;
  let backedUp = false;
  let previousSymlinkTarget: string | null = null;

  if (existsSync(targetPath) || isSymlink(targetPath)) {
    if (isSymlink(targetPath)) {
      try {
        previousSymlinkTarget = readlinkSync(targetPath);
      } catch {
        previousSymlinkTarget = null;
      }
      rmSync(targetPath, { force: true });
    } else {
      if (existsSync(backupPath)) rmSync(backupPath, { force: true });
      renameSync(targetPath, backupPath);
      backedUp = true;
      console.log(`  ${pc.cyan("│")}  ${pc.yellow("⚠")}  backed up ${fileName} → ${fileName}.backup`);
    }
  }

  try {
    if (mode === "copy") {
      copyFileSync(sourcePath, targetPath);
      return { ok: true, message: `copied   ${fileName}` };
    }

    // Windows needs symlink privilege or Developer Mode
    symlinkSync(sourcePath, targetPath, "file");
    return { ok: true, message: `linked   ${fileName}` };
  } catch (err) {
    try {
      // copyFileSync can leave a partial destination; remove it before restore
      if (existsSync(targetPath) || isSymlink(targetPath)) {
        rmSync(targetPath, { force: true });
      }
      if (backedUp) {
        renameSync(backupPath, targetPath);
      } else if (previousSymlinkTarget) {
        symlinkSync(previousSymlinkTarget, targetPath, "file");
      }
    } catch {
      // best-effort restore
    }

    const detail = err instanceof Error ? err.message : String(err);
    if (mode === "symlink") {
      return {
        ok: false,
        message: `failed   ${fileName}  (run as Admin or enable Developer Mode)`,
      };
    }
    return { ok: false, message: `failed   ${fileName}  ${detail}` };
  }
}

function verifyDeploy(targetPath: string, mode: DeployMode): boolean {
  try {
    const linked = isSymlink(targetPath);
    if (mode === "symlink") {
      return linked && existsSync(readlinkSync(targetPath));
    }
    return existsSync(targetPath) && !linked;
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const { mode: modeArg, games: gamesArg, elevatedLog } = parseArgs(process.argv.slice(2));
  const isElevatedWorker = elevatedLog !== "";

  if (isElevatedWorker) {
    attachElevatedLog(elevatedLog);
  } else {
    p.intro(pc.bgCyan(pc.black(" counter-strike-configs ")));
  }

  let selectedGames: GameKey[];

  if (gamesArg === "all") {
    selectedGames = [...VALID_GAMES];
  } else if (Array.isArray(gamesArg)) {
    selectedGames = gamesArg;
  } else {
    const picked = await p.multiselect({
      message: "Which game(s) do you want to deploy configs for?",
      options: VALID_GAMES.map((key) => ({
        value: key,
        label: GAME_LABELS[key],
      })),
      required: true,
    });

    if (p.isCancel(picked)) {
      p.cancel("No games selected. Exiting.");
      process.exit(0);
    }

    selectedGames = picked as GameKey[];
  }

  let mode: DeployMode;

  if (modeArg === "symlink" || modeArg === "copy") {
    mode = modeArg;
  } else {
    const picked = await p.select({
      message: "How would you like to deploy the configs?",
      options: [
        {
          value: "symlink" as const,
          label: "Symlink",
          hint: "requires Admin or Developer Mode — repo changes apply instantly",
        },
        {
          value: "copy" as const,
          label: "Copy",
          hint: "no elevation needed — re-run after each git pull",
        },
      ],
    });

    if (p.isCancel(picked) || (picked !== "symlink" && picked !== "copy")) {
      p.cancel("Cancelled.");
      process.exit(0);
    }

    mode = picked;
  }

  if (mode === "symlink" && process.platform === "win32" && !isElevated()) {
    p.log.warn("Symlink mode requires elevation. Approve the UAC prompt — deploy stays in this terminal.");
    const ok = relaunchElevated(selectedGames, mode);
    if (!ok) {
      p.log.error("UAC was cancelled or elevation failed.");
      p.outro("Try copy mode, or enable Windows Developer Mode for unprivileged symlinks.");
      process.exit(1);
    }
    p.outro("Deploy finished.");
    process.exit(0);
  }

  console.log(`  ${pc.dim(`Mode : ${mode}`)}`);
  console.log(`  ${pc.dim(`Game : ${selectedGames.join(", ")}`)}`);
  console.log();

  type SummaryRow = { game: string; status: string; pass: number; fail: number };
  const summary: SummaryRow[] = [];

  for (const gameKey of selectedGames) {
    const label = GAME_LABELS[gameKey];
    const sourceDir = join(repoRoot, gameKey);

    console.log(`${pc.cyan("┌─")}  ${pc.bold(label)}`);

    const cfgFiles = listCfgFiles(sourceDir);
    if (cfgFiles.length === 0) {
      console.log(`${pc.cyan("│")}  ${pc.yellow("⚠  No .cfg files found in ./" + gameKey + "/ — skipping.")}`);
      console.log(`${pc.cyan("└")}`);
      console.log();
      summary.push({ game: label, status: "SKIPPED (no configs)", pass: 0, fail: 0 });
      continue;
    }

    const targetDir = findCfgPath(gameKey);
    if (!targetDir) {
      console.log(`${pc.cyan("│")}  ${pc.yellow("⚠  Game not found / not installed — skipping.")}`);
      console.log(`${pc.cyan("└")}`);
      console.log();
      summary.push({ game: label, status: "SKIPPED (not installed)", pass: 0, fail: 0 });
      continue;
    }

    if (!existsSync(targetDir)) {
      mkdirSync(targetDir, { recursive: true });
    }

    console.log(`${pc.cyan("│")}  ${pc.dim(`source : ./${gameKey}/`)}`);
    console.log(`${pc.cyan("│")}  ${pc.dim(`target : ${targetDir}`)}`);
    console.log(`${pc.cyan("│")}`);

    let pass = 0;
    let fail = 0;

    for (const fileName of cfgFiles) {
      const sourcePath = join(sourceDir, fileName);
      const targetPath = join(targetDir, fileName);
      const result = deployFile(sourcePath, targetPath, mode);

      if (!result.ok) {
        console.log(`${pc.cyan("│")}  ${pc.red("✘")}  ${result.message}`);
        fail++;
        continue;
      }

      console.log(`${pc.cyan("│")}  ${pc.green("✔")}  ${result.message}`);

      if (verifyDeploy(targetPath, mode)) {
        pass++;
      } else {
        fail++;
      }
    }

    const statusColor = fail === 0 ? pc.green : pc.red;
    console.log(`${pc.cyan("│")}`);
    console.log(`${pc.cyan("└")}  ${statusColor(`${pass} passed`)}  ${pc.dim(`/ ${cfgFiles.length} total`)}`);
    console.log();

    summary.push({
      game: label,
      status: fail === 0 ? "OK" : `PARTIAL (${fail} failed)`,
      pass,
      fail,
    });
  }

  console.log(`${pc.cyan("◆")}  ${pc.bold("Summary")}`);
  for (const row of summary) {
    const skipped = row.status.startsWith("SKIPPED");
    const icon = row.status === "OK" ? pc.green("✔") : skipped ? pc.yellow("–") : pc.red("✘");
    const statusText = row.status === "OK"
      ? pc.green(row.status)
      : skipped
        ? pc.yellow(row.status)
        : pc.red(row.status);
    console.log(`${pc.cyan("│")}  ${icon}  ${row.game}  ${pc.dim(statusText)}`);
  }
  console.log(`${pc.cyan("└")}`);
  console.log();

  if (isElevatedWorker) {
    console.log("Deploy finished.");
  } else {
    p.outro("Deploy finished.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
