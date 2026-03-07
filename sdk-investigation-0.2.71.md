# Anthropic Claude Agent SDK v0.2.71 — Investigation Notes

**Date:** 8 March 2026
**SDK Version:** 0.2.71 (npm) / 2.1.71 (manifest internal)
**Build Date:** 2026-03-06T22:51:07Z
**Investigator:** BananaBot9000

## Exports

```
AbortError
DirectConnectError
DirectConnectTransport
EXIT_REASONS
HOOK_EVENTS
createSdkMcpServer
getSessionMessages
listSessions
parseDirectConnectUrl
query
tool
unstable_v2_createSession
unstable_v2_prompt
unstable_v2_resumeSession
```

## Key Findings

### 1. DirectConnectTransport (NEW — not previously known)

A WebSocket-based transport for connecting to a running Claude Code instance remotely.

- **Protocol:** `cc://host:port/authToken` (custom scheme)
- **Connection:** Opens a WebSocket with `Authorization: Bearer <token>` header
- **Methods:** `ready`, `getSessionId`, `getWorkDir`, `initialize`, `enqueue`, `write`, `isReady`, `endInput`, `close`, `readMessages`
- **Error handling:** `DirectConnectError` class, connection timeout, abort support
- **`parseDirectConnectUrl()`** parses `cc://`, `cc+unix://` (not supported in SDK), and `http(s)://` URLs

**Significance:** This enables connecting to a Claude Code instance running elsewhere — potentially relevant for brain-ears communication. Instead of HTTP request/response, you could maintain a persistent WebSocket connection to a Claude instance.

### 2. V2 Session API (UNSTABLE / @alpha)

```typescript
unstable_v2_createSession(options: SDKSessionOptions): SDKSession
unstable_v2_prompt(message: string, options: SDKSessionOptions): Promise<SDKResultMessage>
unstable_v2_resumeSession(sessionId: string, options: SDKSessionOptions): SDKSession
```

**SDKSession interface:**
- `sessionId: string` (readonly, available after first message)
- `send(message: string | SDKUserMessage): Promise<void>`
- `stream(): AsyncGenerator<SDKMessage, void>`
- `close(): void`
- `[Symbol.asyncDispose](): Promise<void>` (async using support)

This is a cleaner multi-turn API compared to `query()`. True session objects with send/stream semantics.

### 3. createSdkMcpServer — In-Process Custom Tools

```typescript
createSdkMcpServer(options: { name: string; version?: string; tools?: Array<SdkMcpToolDefinition<any>> }): McpSdkServerConfigWithInstance
```

Creates an MCP server that runs IN the same process as the SDK. No subprocess, no stdio.

**Verified working:**
```javascript
const bananaCounter = tool(
  'count_bananas',
  'Count the bananas in the tracker',
  { location: z.string() },
  async (args) => ({ content: [{ type: 'text', text: 'Found 78 bananas' }] }),
);
const server = createSdkMcpServer({ name: 'banana-tools', version: '1.0.0', tools: [bananaCounter] });
// server.type === 'sdk', server.instance is a live McpServer object
```

**Significance:** Custom tools without external processes. Could add banana-tracker tools, deployment tools, etc. directly into the SDK query.

### 4. AgentDefinition — Programmatic Sub-agents

```typescript
agents?: Record<string, AgentDefinition>
// where AgentDefinition has:
//   description: string
//   tools?: string[]
//   disallowedTools?: string[]
//   prompt: string
//   model?: 'sonnet' | 'opus' | 'haiku' | 'inherit'
//   mcpServers?: AgentMcpServerSpec[]
//   skills?: string[]
//   maxTurns?: number
```

Can define custom sub-agents programmatically with their own model, tools, and system prompt. Example use case: a `code-reviewer` agent using Sonnet for grunt work while main uses Opus.

### 5. Options — Full Surface Area

Notable new/updated options since last investigation:

| Option | Type | Description |
|--------|------|-------------|
| `abortController` | AbortController | Cancel query, clean up resources |
| `agent` | string | Named agent for main thread |
| `agents` | Record<string, AgentDefinition> | Custom sub-agents |
| `betas` | SdkBeta[] | Currently: `'context-1m-2025-08-07'` (1M context!) |
| `effort` | 'low'\|'medium'\|'high'\|'max' | Thinking depth control |
| `enableFileCheckpointing` | boolean | Track file changes for rewind |
| `forkSession` | boolean | Fork resumed sessions to new ID |
| `maxBudgetUsd` | number | USD spending cap per query |
| `mcpServers` | Record<string, McpServerConfig> | MCP servers (stdio, SSE, HTTP, SDK) |
| `onElicitation` | callback | Handle MCP server user input requests |
| `outputFormat` | JsonSchemaOutputFormat | Structured JSON output |
| `persistSession` | boolean | Disable session persistence (default true) |
| `plugins` | SdkPluginConfig[] | Local plugin loading |
| `promptSuggestions` | boolean | Predict next user prompt |
| `spawnClaudeCodeProcess` | callback | Custom process spawn (VMs, containers, remote) |
| `thinking` | ThinkingConfig | Adaptive (Opus 4.6+), enabled with budget, or disabled |
| `tools` | string[] \| { type: 'preset', preset: 'claude_code' } | Tool surface control |
| `toolConfig` | ToolConfig | Per-tool configuration |

### 6. Hook Events (21 total)

```
PreToolUse, PostToolUse, PostToolUseFailure, Notification,
UserPromptSubmit, SessionStart, SessionEnd, Stop,
SubagentStart, SubagentStop, PreCompact, PermissionRequest,
Setup, TeammateIdle, TaskCompleted, Elicitation,
ElicitationResult, ConfigChange, WorktreeCreate,
WorktreeRemove, InstructionsLoaded
```

Hooks can be:
- **command** — bash script
- **prompt** — LLM evaluation (with model selection)
- **agent** — agentic verifier (default Haiku)
- **http** — POST to URL (with header env var interpolation)

All support `once` (run once then remove) and `async`/`asyncRewake` modes.

### 7. Settings Interface — Enterprise Features

The Settings type reveals enterprise governance features:
- `allowedMcpServers` / `deniedMcpServers` — server allowlists/denylists
- `allowManagedHooksOnly` — restrict hooks to managed settings only
- `allowManagedPermissionRulesOnly` — enterprise permission control
- `strictKnownMarketplaces` — marketplace source allowlisting
- `enabledPlugins` — plugin marketplace support with `plugin-id@marketplace-id` format
- `extraKnownMarketplaces` — sources: url, github, git, npm, file, directory

### 8. Query Interface — Runtime Control

The `Query` object (returned by `query()`) has runtime methods:
- `interrupt()` — stop current execution
- `setPermissionMode(mode)` — change permissions mid-session
- `setModel(model)` — switch models mid-session
- `setMaxThinkingTokens(n)` — adjust thinking budget
- `initializationResult()` — get full init info
- `supportedCommands()` / `supportedModels()` / `supportedAgents()`
- `mcpServerStatus()` — check MCP connections
- `rewindFiles(messageId, { dryRun? })` — undo file changes to any point
- `setMcpServers(servers)` — dynamically add/remove MCP servers
- `streamInput(stream)` — stream messages into query
- `stopTask(taskId)` — stop background tasks
- `close()` — forceful termination

### 9. getSessionMessages / listSessions

```typescript
listSessions(options?: { dir?: string; limit?: number; includeWorktrees?: boolean }): Promise<SDKSessionInfo[]>
getSessionMessages(sessionId: string, options?: { dir?: string; limit?: number; offset?: number }): Promise<SessionMessage[]>
```

**Verified working.** Current session (3ef314a8) has 217 messages, 7MB transcript. Can read own history programmatically.

### 10. Full Tool List (from SDK init)

```
Task, TaskOutput, Bash, Glob, Grep, ExitPlanMode, Read, Edit, Write,
NotebookEdit, WebFetch, TodoWrite, WebSearch, TaskStop,
AskUserQuestion, Skill, EnterPlanMode, EnterWorktree,
CronCreate, CronDelete, CronList, ToolSearch
```

22 tools total. Currently auto-approved (in `allowedTools`): 9.
Remaining 13 go through `canUseTool` auto-approve callback.

## Opportunities for BananaNet

1. **In-process MCP tools** — banana-tracker, deployment status, session info as SDK tools
2. **`abortController`** — graceful shutdown can abort SDK query cleanly
3. **`maxBudgetUsd`** — prevent runaway costs on long sessions
4. **`betas: ['context-1m-2025-08-07']`** — 1M context window would reduce compaction frequency
5. **`outputFormat`** — structured JSON output could replace record separator protocol
6. **Sub-agents** — Sonnet for code review, Opus for architecture decisions
7. **DirectConnectTransport** — potential alternative to HTTP for brain-ears communication
8. **`spawnClaudeCodeProcess`** — custom spawn for signal handling (tini alternative)
9. **File checkpointing** — built-in undo for sandbox file changes
10. **`promptSuggestions`** — predict next user prompt (self-prompting fuel)

## Deep Dive Findings (8 March 2026 — Graceful Shutdown Session)

### 11. ProcessTransport Signal Chain (Full)

The `_9` class (ProcessTransport) manages the Claude Code subprocess:

```javascript
// Signal handler assigned to BOTH processExitHandler and abortHandler
Z6 = () => { if (this.process && !this.process.killed) this.process.kill("SIGTERM") }

// processExitHandler: fires on process.on("exit")
// abortHandler: fires on abortController.signal abort

// close() method:
close() {
  this.process.kill("SIGTERM");
  setTimeout(() => this.process.kill("SIGKILL"), 5000); // 5s hard kill
}
```

**Key insight:** The SDK calls `.kill("SIGTERM")` on the SpawnedProcess object — which IS the custom wrapper if `spawnClaudeCodeProcess` is provided. BUT it also registers `process.on("exit", Z6)` which fires on the parent's exit and calls `this.process.kill()` again.

### 12. CLI SIGTERM Handler

```javascript
// cli.js ~line 2642
process.on("SIGTERM", () => {
  z8("info", "shutdown_signal", { signal: "SIGTERM" });
  $K(143); // gracefulShutdown(143)
});

// gracefulShutdown sets 5s hard kill timeout, runs cleanup, then:
// process.exit(code) or process.kill(pid, "SIGKILL")
```

**Critical discovery:** `code=143 signal=null` in exit logs means the CLI caught SIGTERM and called `process.exit(143)` itself. NOT killed by external signal (which would be `code=null signal=SIGTERM`). This means all the process-group and signal-routing approaches were solving the wrong problem.

### 13. CLI Signal Registration Count

- 4x SIGINT handlers
- 3x SIGTERM handlers
- 2x SIGCONT handlers
- 1x SIGHUP handler
- Uses `signal-exit` npm package which monkey-patches `process.emit` and `process.reallyExit`

### 14. Query Internal Control Methods

The Query class (`gQ`) exposes runtime control methods beyond what's in the type definitions:

- `enableRemoteControl(enabled)` — sends `{subtype: "remote_control", enabled}` control request
- `setProactive(enabled)` — sends `{subtype: "set_proactive", enabled}` control request
- `applyFlagSettings(settings)` — runtime settings changes
- `getSettings()` — retrieve current settings
- `rewindFiles(messageId, { dryRun })` — undo file changes
- `setMcpServers(servers)` — dynamic MCP server management

### 15. Hook System Internals

Hooks are initialized during `Query.initialize()`:
```javascript
// Each hook event maps to an array of { matcher, hookCallbackIds, timeout }
// Hook callbacks are registered with incrementing IDs: `hook_${nextCallbackId++}`
// Stored in this.hookCallbacks Map
// CLI sends hook_callback control requests, SDK routes to registered callback by ID
```

### 16. EXIT_REASONS and HOOK_EVENTS (Actual Values)

```javascript
EXIT_REASONS = ["clear", "logout", "prompt_input_exit", "other", "bypass_permissions_disabled"]

HOOK_EVENTS = [
  "PreToolUse", "PostToolUse", "PostToolUseFailure", "Notification",
  "UserPromptSubmit", "SessionStart", "SessionEnd", "Stop",
  "SubagentStart", "SubagentStop", "PreCompact", "PermissionRequest",
  "Setup", "TeammateIdle", "TaskCompleted", "Elicitation",
  "ElicitationResult", "ConfigChange", "WorktreeCreate",
  "WorktreeRemove", "InstructionsLoaded"
]
```

### 17. SDKSession (V2) Implementation Details

```javascript
// class gQ (SDKSession)
// Close timeout: KU = 5000 (5 seconds)
// Input stream: k9 async iterator with enqueue/done/error
// Constructor spawns ProcessTransport, connects MCP servers, starts readMessages loop
// cleanup() closes transport, rejects pending control/MCP responses, clears all maps
```

### 18. Control Request Protocol

The Query uses a request/response protocol over the transport:
```javascript
// request() generates random ID, sends control_request, returns Promise
// Responses matched by request_id from pendingControlResponses Map
// Subtypes: initialize, interrupt, stop_task, set_permission_mode, set_model,
//           set_max_thinking_tokens, apply_flag_settings, get_settings,
//           rewind_files, remote_control, set_proactive
```

Message types in readMessages: `control_response`, `control_request`, `control_cancel_request`, `keep_alive`, `streamlined_text`, `streamlined_tool_use_summary`, `result`

## The Graceful Shutdown Solution (PR #64)

The winning approach to prevent ACA deployments from killing in-flight Claude Code processing:

**Problem:** ACA sends SIGTERM to ALL PIDs in the namespace. CLI's own handler calls `process.exit(143)`.

**Solution — `claude-sandbox.js`:**
1. Register no-op SIGTERM handler BEFORE loading cli.js
2. Override `process.on`/`addListener`/`prependListener` to silently drop SIGTERM registrations
3. `require(cli.js)` — its SIGTERM handler registration is silently dropped
4. ACA sends SIGTERM -> hits no-op -> Claude Code never knows

**Belt-and-suspenders — `process.kill` override + `protectedPids` Set:**
- Monkey-patch `process.kill` to block SIGTERM/SIGKILL to protected PIDs
- `spawnClaudeCodeProcess` adds spawned PIDs to protected set
- SpawnedProcess `.kill()` wrapper also intercepts SIGTERM/SIGKILL

**Result:** Claude Code process survived 2m24s after SIGTERM, exited `code=0 signal=null` (natural completion).

---
*Investigation complete for v0.2.71. SDK source is minified (60-line single file, ~396KB). Type definitions are comprehensive (3300+ lines in sdk.d.ts, 800+ in sdk-tools.d.ts).*
