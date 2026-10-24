import { createInterface } from "node:readline";
import { mkdir, readFile, rename, unlink, writeFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import os from "node:os";
import path from "node:path";

const root = path.dirname(fileURLToPath(import.meta.url));
const appUri = "ui://earning-dashboard/app";
const appMeta = {
  ui: { csp: { connectDomains: [], resourceDomains: [] } },
  "openai/ui": { availableDisplayModes: ["fullscreen"] }
};
const appToolMeta = { "ui/resourceUri": appUri, ui: { resourceUri: appUri } };
const trackerKeys = ["work", "attempts", "stopped", "tasks", "taskHistory", "activity", "library"];
const trackerHome = process.env.LOCALAPPDATA ? path.join(process.env.LOCALAPPDATA, "EarningDashboard") : path.join(process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share"), "EarningDashboard");
const trackerFile = path.join(trackerHome, "tracker.json");

function blankTracker() {
  return { version: 2, goal: { target: 200, deadline: "2026-11-23" }, work: [], attempts: [], stopped: [], tasks: [], taskHistory: [], activity: [], library: [] };
}

function validSeed(value) {
  return value?.goal && (value.version === 1 && ["work", "attempts", "stopped", "tasks"].every(key => Array.isArray(value[key])) || value.version === 2 && trackerKeys.every(key => Array.isArray(value[key])));
}

function validTracker(value) {
  return value?.version === 2 && value.goal && Number.isFinite(Number(value.goal.target)) && Number(value.goal.target) > 0 && trackerKeys.every(key => Array.isArray(value[key]));
}

async function readSeed() {
  try {
    const seed = JSON.parse(await readFile(path.join(root, "seed.json"), "utf8"));
    if (!validSeed(seed)) throw new Error("The local tracker seed is invalid; it was left untouched.");
    return seed;
  } catch (error) {
    if (error.code === "ENOENT") return blankTracker();
    throw error;
  }
}

async function readTracker() {
  try {
    const tracker = JSON.parse(await readFile(trackerFile, "utf8"));
    if (!validTracker(tracker)) throw new Error("The saved earning tracker is invalid; it was left untouched.");
    return { tracker, persisted: true };
  } catch (error) {
    if (error.code === "ENOENT") return { tracker: await readSeed(), persisted: false };
    throw error;
  }
}

class TrackerInputError extends Error {}

function validateUpdate(value, previous) {
  if (!validTracker(value)) throw new TrackerInputError("Tracker must be a version 2 snapshot with all seven record lists.");
  if (JSON.stringify(value).length > 2_000_000) throw new TrackerInputError("Tracker snapshot exceeds the 2 MB limit.");
  for (const key of trackerKeys) {
    const ids = new Set();
    for (const item of value[key]) {
      if (!item || typeof item.id !== "string" || !item.id.trim() || ids.has(item.id)) throw new TrackerInputError(`${key} records need unique, nonempty IDs.`);
      ids.add(item.id);
    }
  }
  for (const task of value.tasks) if (task.done === true) throw new TrackerInputError("Owner tasks cannot be marked complete in the tracker.");
  if (Number(value.goal.target) <= 0) throw new TrackerInputError("Goal target must be positive.");
  for (const attempt of value.attempts) {
    if (!["pending", "submitted", "no-result", "credited"].includes(attempt.status)) throw new TrackerInputError("Attempt status is not supported.");
    const amount = Number(attempt.amount);
    if (!Number.isFinite(amount) || amount < 0) throw new TrackerInputError("Attempt amounts must be nonnegative numbers.");
    const settled = attempt.settlement?.status === "settled" && typeof attempt.settlement.reference === "string" && attempt.settlement.reference.trim();
    if (attempt.status === "credited") {
      if (!attempt.settlement || typeof attempt.settlement.reference !== "string" || attempt.settlement.reference.trim().length > 200) throw new TrackerInputError("Settlement reference must be at most 200 characters.");
      if (amount <= 0 || !settled) throw new TrackerInputError("Credited earnings need a positive amount and a settled payment reference.");
    } else if (amount !== 0) throw new TrackerInputError("Only settled credited attempts may carry an earning amount.");
  }
  for (const entry of value.activity) if (Number(entry.amount || 0) !== 0) throw new TrackerInputError("Activity amounts must be zero; record earnings in settled attempts only.");

  const keep = (from, to, label) => {
    const ids = new Set(to.map(item => item.id));
    for (const item of from) if (!ids.has(item.id)) throw new TrackerInputError(`Cannot remove existing ${label} record ${item.id}; move it to its history list instead.`);
  };
  const previousLists = Object.fromEntries(trackerKeys.map(key => [key, previous[key] || []]));
  keep(previousLists.attempts, value.attempts, "attempt");
  keep(previousLists.stopped, value.stopped, "stopped work");
  keep(previousLists.taskHistory, value.taskHistory, "closed owner task");
  keep(previousLists.activity, value.activity, "activity");
  keep(previousLists.library, value.library, "library");
  keep(previousLists.work, [...value.work, ...value.stopped], "work");
  keep(previousLists.tasks, [...value.tasks, ...value.taskHistory], "owner task");
  const nextAttempts = new Map(value.attempts.map(item => [item.id, item]));
  for (const attempt of previousLists.attempts) {
    if (attempt.status !== "credited" || attempt.settlement?.status !== "settled") continue;
    const next = nextAttempts.get(attempt.id);
    if (next.status !== attempt.status || Number(next.amount) !== Number(attempt.amount) || next.settlement?.reference !== attempt.settlement.reference) throw new TrackerInputError("Settled earnings are immutable so saved income cannot be erased or changed.");
  }
}

async function writeTracker(tracker) {
  const { tracker: previous } = await readTracker();
  validateUpdate(tracker, previous);
  const directory = path.dirname(trackerFile);
  await mkdir(directory, { recursive: true });
  const temporary = `${trackerFile}.${process.pid}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporary, `${JSON.stringify(tracker, null, 2)}\n`, { flag: "wx" });
    await rename(temporary, trackerFile);
  } catch (error) {
    try { await unlink(temporary); } catch {}
    throw error;
  }
  return { tracker, persisted: true };
}

async function appHtml() {
  const html = await readFile(path.join(root, "index.html"), "utf8");
  const { tracker, persisted } = await readTracker();
  const safeJson = JSON.stringify(tracker).replaceAll("<", "\\u003c");
  const injection = `<script>window.__EARNING_DASHBOARD_SEED__=${safeJson};window.__EARNING_DASHBOARD_PERSISTED__=${persisted};</script>`;
  return html.replace("<!--EARNING_DASHBOARD_SEED-->", injection);
}

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function result(request, value) {
  if (Object.hasOwn(request, "id")) send({ jsonrpc: "2.0", id: request.id, result: value });
}

function fail(request, code, message) {
  if (Object.hasOwn(request, "id")) send({ jsonrpc: "2.0", id: request.id, error: { code, message } });
}

function tool(name, title, description, schema, readOnly = true) {
  return { name, title, description, inputSchema: schema, annotations: { readOnlyHint: readOnly, destructiveHint: false, openWorldHint: false }, ...(name === "open_earning_dashboard" ? { _meta: appToolMeta } : {}) };
}

async function handle(request) {
  if (!request || request.jsonrpc !== "2.0" || typeof request.method !== "string") {
    fail(request ?? {}, -32600, "Invalid JSON-RPC request");
    return;
  }
  if (!Object.hasOwn(request, "id")) return;
  const params = request.params ?? {};
  switch (request.method) {
    case "initialize":
      result(request, {
        protocolVersion: params.protocolVersion ?? "2025-06-18",
        capabilities: { tools: { listChanged: false }, resources: { listChanged: false } },
        serverInfo: { name: "earning-dashboard", version: "0.1.6" }
      });
      return;
    case "ping":
      result(request, {});
      return;
    case "tools/list":
      result(request, {
        tools: [
          tool("open_earning_dashboard", "Open earning dashboard", "Open the local dashboard for active work, attempts, owner steps, and settled earnings.", { type: "object", properties: {}, additionalProperties: false }),
          tool("read_earning_tracker", "Read earning tracker", "Read the device-local tracker. Earnings count only when an attempt is credited with a positive amount and a settled payment reference.", { type: "object", properties: {}, additionalProperties: false }),
          tool("update_earning_tracker", "Update earning tracker", "Save a version 2 tracker snapshot. Preserve existing records, never mark owner tasks complete, keep activity amounts at zero, and include a settled payment reference for every credited earning.", { type: "object", properties: { tracker: { type: "object", description: "The complete version 2 tracker snapshot." } }, required: ["tracker"], additionalProperties: false }, false)
        ]
      });
      return;
    case "tools/call": {
      const args = params.arguments ?? {};
      if (params.name === "open_earning_dashboard") {
        result(request, { content: [{ type: "text", text: "Open the earning dashboard panel." }], _meta: appToolMeta });
        return;
      }
      if (params.name === "read_earning_tracker") {
        try {
          const value = await readTracker();
          result(request, { content: [{ type: "text", text: "Loaded the local earning tracker." }], structuredContent: value });
        } catch (error) { fail(request, -32603, `Could not read the earning tracker: ${error.message}`); }
        return;
      }
      if (params.name === "update_earning_tracker") {
        try {
          const value = await writeTracker(args.tracker);
          result(request, { content: [{ type: "text", text: "Saved the local earning tracker." }], structuredContent: value });
        } catch (error) { fail(request, error instanceof TrackerInputError ? -32602 : -32603, `Could not save the earning tracker: ${error.message}`); }
        return;
      }
      fail(request, -32602, "Unknown tool");
      return;
    }
    case "resources/list":
      result(request, {
        resources: [{ uri: appUri, name: "Earning dashboard", mimeType: "text/html;profile=mcp-app", _meta: appMeta }]
      });
      return;
    case "resources/read":
      if (params.uri !== appUri) {
        fail(request, -32602, "Unknown resource");
        return;
      }
      try {
        result(request, {
          contents: [{ uri: appUri, mimeType: "text/html;profile=mcp-app", text: await appHtml(), _meta: appMeta }]
        });
      } catch (error) {
        fail(request, -32603, `Could not load dashboard: ${error.message}`);
      }
      return;
    default:
      fail(request, -32601, "Method not found");
  }
}

const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of input) {
  if (!line.trim()) continue;
  try {
    await handle(JSON.parse(line));
  } catch (error) {
    console.error(`Earning dashboard MCP error: ${error.message}`);
  }
}