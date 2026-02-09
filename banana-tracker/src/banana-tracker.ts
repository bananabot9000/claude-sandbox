import * as fs from "fs";
import * as path from "path";
import * as readline from "readline";

// ============ Types ============
interface BananaEntry {
  id: number;
  who: string;
  count: number;
  reason: string;
  timestamp: string;
}

interface BananaData {
  entries: BananaEntry[];
  nextId: number;
}

// ============ Storage ============
const DATA_FILE = path.join(__dirname, "..", "bananas.json");

function loadData(): BananaData {
  if (fs.existsSync(DATA_FILE)) {
    return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
  }
  return { entries: [], nextId: 1 };
}

function saveData(data: BananaData): void {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// ============ Commands ============
function addBanana(who: string, count: number, reason: string): BananaEntry {
  const data = loadData();
  const entry: BananaEntry = {
    id: data.nextId++,
    who,
    count,
    reason,
    timestamp: new Date().toISOString(),
  };
  data.entries.push(entry);
  saveData(data);
  return entry;
}

function listBananas(): BananaEntry[] {
  return loadData().entries;
}

function leaderboard(): { who: string; total: number }[] {
  const data = loadData();
  const totals = new Map<string, number>();

  for (const entry of data.entries) {
    totals.set(entry.who, (totals.get(entry.who) || 0) + entry.count);
  }

  return [...totals.entries()]
    .map(([who, total]) => ({ who, total }))
    .sort((a, b) => b.total - a.total);
}

function stats(): {
  totalBananas: number;
  totalEntries: number;
  topHolder: string;
  averagePerEntry: number;
} {
  const data = loadData();
  const totalBananas = data.entries.reduce((sum, e) => sum + e.count, 0);
  const board = leaderboard();

  return {
    totalBananas,
    totalEntries: data.entries.length,
    topHolder: board.length > 0 ? board[0].who : "nobody yet",
    averagePerEntry:
      data.entries.length > 0
        ? Math.round((totalBananas / data.entries.length) * 10) / 10
        : 0,
  };
}

function removeBanana(id: number): boolean {
  const data = loadData();
  const idx = data.entries.findIndex((e) => e.id === id);
  if (idx === -1) return false;
  data.entries.splice(idx, 1);
  saveData(data);
  return true;
}

// ============ CLI ============
const RAINBOW_BANANAS = ["🔴", "🟠", "🟡", "🟢", "🔵", "🟣"];
const BANANA = "🍌";
const TROPHY = "🏆";

function rainbowBananas(count: number): string {
  const display = Math.min(count, 20);
  return Array.from({ length: display }, (_, i) => RAINBOW_BANANAS[i % RAINBOW_BANANAS.length]).join("");
}

function printHelp(): void {
  console.log(`
${BANANA} BANANA TRACKER v1.0 ${BANANA}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands:
  add <who> <count> <reason>  - Track bananas for someone
  list                        - Show all banana entries
  leaderboard                 - Show the banana leaderboard
  stats                       - Show banana statistics
  remove <id>                 - Remove a banana entry
  help                        - Show this help message
  exit                        - Exit the tracker

Dedicated to retaxis, the original banana lover ${BANANA}
`);
}

function printBanner(): void {
  console.log(`
  ╔══════════════════════════════════╗
  ║   ${BANANA} BANANA TRACKER v1.0 ${BANANA}      ║
  ║   For retaxis, with love         ║
  ╚══════════════════════════════════╝
  `);
}

async function main(): Promise<void> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const prompt = (): Promise<string> =>
    new Promise((resolve) => rl.question(`${BANANA} > `, resolve));

  printBanner();
  printHelp();

  // Handle non-interactive mode (command line args)
  const args = process.argv.slice(2);
  if (args.length > 0) {
    handleCommand(args.join(" "));
    rl.close();
    return;
  }

  // Interactive mode
  while (true) {
    const input = (await prompt()).trim();
    if (!input) continue;
    if (input === "exit" || input === "quit") {
      console.log(`\nBye bye! Keep tracking those bananas! ${BANANA}\n`);
      rl.close();
      break;
    }
    handleCommand(input);
  }
}

function handleCommand(input: string): void {
  const parts = input.split(/\s+/);
  const cmd = parts[0].toLowerCase();

  switch (cmd) {
    case "add": {
      const who = parts[1];
      const count = parseInt(parts[2], 10);
      const reason = parts.slice(3).join(" ") || "just because";

      if (!who || isNaN(count)) {
        console.log("Usage: add <who> <count> <reason>");
        console.log('Example: add retaxis 5 "found them on sale"');
        break;
      }

      const entry = addBanana(who, count, reason);
      console.log(
        `\n${BANANA} Added ${count} banana(s) for ${who}! (ID: ${entry.id})`
      );
      console.log(`   Reason: ${reason}`);
      console.log(`   Time: ${entry.timestamp}\n`);
      break;
    }

    case "list": {
      const entries = listBananas();
      if (entries.length === 0) {
        console.log(`\nNo bananas tracked yet! Use "add" to get started ${BANANA}\n`);
        break;
      }
      console.log(`\n${BANANA} All Banana Entries:`);
      console.log("━".repeat(60));
      for (const e of entries) {
        console.log(
          `  #${e.id} | ${e.who.padEnd(15)} | ${String(e.count).padStart(4)} ${rainbowBananas(e.count)} | ${e.reason}`
        );
      }
      console.log("━".repeat(60));
      console.log(`  Total entries: ${entries.length}\n`);
      break;
    }

    case "leaderboard": {
      const board = leaderboard();
      if (board.length === 0) {
        console.log(`\nNo bananas tracked yet! ${BANANA}\n`);
        break;
      }
      console.log(`\n${TROPHY} Banana Leaderboard ${TROPHY}`);
      console.log("━".repeat(40));
      board.forEach((entry, i) => {
        const medal = i === 0 ? "👑" : i === 1 ? "🥈" : i === 2 ? "🥉" : "  ";
        const bar = rainbowBananas(entry.total);
        console.log(`  ${medal} ${entry.who.padEnd(15)} ${String(entry.total).padStart(4)} ${bar}`);
      });
      console.log("━".repeat(40) + "\n");
      break;
    }

    case "stats": {
      const s = stats();
      console.log(`\n📊 Banana Statistics:`);
      console.log("━".repeat(40));
      console.log(`  Total bananas:     ${s.totalBananas} ${BANANA}`);
      console.log(`  Total entries:     ${s.totalEntries}`);
      console.log(`  Top banana holder: ${s.topHolder} ${TROPHY}`);
      console.log(`  Avg per entry:     ${s.averagePerEntry}`);
      console.log("━".repeat(40) + "\n");
      break;
    }

    case "remove": {
      const id = parseInt(parts[1], 10);
      if (isNaN(id)) {
        console.log("Usage: remove <id>");
        break;
      }
      if (removeBanana(id)) {
        console.log(`\n✅ Removed banana entry #${id}\n`);
      } else {
        console.log(`\n❌ No entry found with ID #${id}\n`);
      }
      break;
    }

    case "help":
      printHelp();
      break;

    default:
      console.log(`\n❓ Unknown command: "${cmd}". Type "help" for commands.\n`);
  }
}

main().catch(console.error);
