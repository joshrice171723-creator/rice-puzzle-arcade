import { createInterface } from "node:readline";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.dirname(fileURLToPath(import.meta.url));
const appUri = "ui://earning-dashboard/app";
const appMeta = {
  ui: { csp: { connectDomains: [], resourceDomains: [] } },
  "openai/ui": { availableDisplayModes: ["fullscreen"] }
};
const appToolMeta = { "ui/resourceUri": appUri, ui: { resourceUri: appUri } };

function validSeed(value) {
  return value?.goal && (value.version === 1 && ["work", "attempts", "stopped", "tasks"].every(key => Array.isArray(value[key])) || value.version === 2 && ["work", "attempts", "stopped", "tasks", "taskHistory", "activity", "library"].every(key => Array.isArray(value[key])));
}

async function appHtml() {
  const html = await readFile(path.join(root, "index.html"), "utf8");
  let injection = "";
  try {
    const seed = JSON.parse(await readFile(path.join(root, "seed.json"), "utf8"));
    if (validSeed(seed)) {
      const safeJson = JSON.stringify(seed).replaceAll("<", "\\u003c");
      injection = `<script>window.__EARNING_DASHBOARD_SEED__=${safeJson};</script>`;
    }
  } catch {}
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
        serverInfo: { name: "earning-dashboard", version: "0.1.5" }
      });
      return;
    case "ping":
      result(request, {});
      return;
    case "tools/list":
      result(request, {
        tools: [{
          name: "open_earning_dashboard",
          title: "Open earning dashboard",
          description: "Open the local dashboard for active work, attempts, stopped efforts, owner tasks, and credited earnings.",
          inputSchema: { type: "object", properties: {}, additionalProperties: false },
          annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false },
          _meta: appToolMeta
        }]
      });
      return;
    case "tools/call":
      if (params.name !== "open_earning_dashboard") {
        fail(request, -32602, "Unknown tool");
        return;
      }
      result(request, { content: [{ type: "text", text: "Open the earning dashboard panel." }], _meta: appToolMeta });
      return;
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
