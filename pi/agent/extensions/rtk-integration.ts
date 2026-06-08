/**
 * RTK Integration for pi — cross-platform command rewrite plugin.
 *
 * Rewrites bash commands via `rtk rewrite` for token savings.
 * Compatible with both @earendil-works/pi-coding-agent and @oh-my-pi/pi-coding-agent.
 *
 * Requires: rtk >= 0.23.0 in PATH.
 *
 * All rewrite logic lives in `rtk rewrite` (src/discover/registry.rs).
 * To add or change rewrite rules, edit the Rust registry — not this file.
 *
 * Exit code contract for `rtk rewrite`:
 *   0 + stdout  Rewrite found → mutate command
 *   1           No RTK equivalent → pass through unchanged
 *   3 + stdout  Rewrite (advisory) → mutate command
 */

const REWRITE_TIMEOUT_MS = 2_000
const MIN_SUPPORTED_RTK_MINOR = 23

// Commands whose rtk rewrites change output format — skip to preserve agent assumptions.
const SKIP: Record<string, true> = { ls: true, find: true };

// Minimal type definitions for cross-platform compatibility.
// Both @earendil-works/pi-coding-agent and @oh-my-pi/pi-coding-agent share these shapes.
interface ExecResult {
  stdout: string
  stderr: string
  code: number
  killed: boolean
}

interface ExtensionAPI {
  exec(command: string, args: string[], options?: { timeout?: number; signal?: AbortSignal }): Promise<ExecResult>
  on(event: string, handler: (event: any, ctx: any) => any): void
}

// Parse "X.Y.Z" semver, return [major, minor, patch] or null.
function parseSemver(raw: string): [number, number, number] | null {
  const m = raw.trim().match(/(\d+)\.(\d+)\.(\d+)/)
  if (!m) return null
  return [parseInt(m[1], 10), parseInt(m[2], 10), parseInt(m[3], 10)]
}

// Check if event is a bash tool call (cross-platform).
// Both platforms use { type: "tool_call", toolName: "bash", input: { command: string } }.
function isBashToolCall(event: unknown): event is { input: { command: string } } {
  if (!event || typeof event !== "object") return false
  const e = event as Record<string, unknown>
  return e.type === "tool_call" && e.toolName === "bash"
}

// Calls `rtk rewrite`; returns the rewritten command or null (pass through).
async function rewriteCommand(
  pi: ExtensionAPI,
  cmd: string,
  signal?: AbortSignal
): Promise<string | null> {
  const result = await pi.exec("rtk", ["rewrite", cmd], {
    timeout: REWRITE_TIMEOUT_MS,
    signal,
  })
  if (result.killed) return null
  if (result.code !== 0 && result.code !== 3) return null
  return result.stdout.trim() || null
}

export default async function (pi: ExtensionAPI) {
  // Probe rtk version at load time; disable extension if missing or too old.
  const ver = await pi.exec("rtk", ["--version"], { timeout: REWRITE_TIMEOUT_MS })
  if (ver.code !== 0) {
    console.warn("[rtk] rtk binary not found in PATH — extension disabled")
    return
  }

  // Warn and bail if rtk predates 0.23.0 (when `rtk rewrite` was introduced).
  const parsed = parseSemver(ver.stdout.replace(/^rtk\s+/, ""))
  if (parsed) {
    const [major, minor] = parsed
    if (major === 0 && minor < MIN_SUPPORTED_RTK_MINOR) {
      console.warn(`[rtk] rtk ${ver.stdout.trim()} is too old (need >= 0.23.0) — extension disabled`)
      return
    }
  }

  pi.on("session_start", async (_event: unknown, ctx: any) => {
    if (ctx?.ui?.setStatus) {
      // official pi: ctx.ui.theme.fg() for colored text
      // oh-my-pi: plain text (no theme on ui)
      const text = ctx.ui.theme?.fg
        ? ctx.ui.theme.fg("accent", "RTK ✓")
        : "RTK ✓"
      ctx.ui.setStatus("rtk-integration", text)
    }
  })

  pi.on("tool_call", async (event: unknown, ctx: any) => {
    try {
      if (!isBashToolCall(event)) return

      const cmd = event.input.command
      if (typeof cmd !== "string" || cmd.trim() === "") return
      if (cmd.startsWith("rtk ")) return
      if (process.env.RTK_DISABLED === "1") return

      // Skip commands that change output format in ways that break agent assumptions.
      const baseCmd = cmd.trimStart().split(/\s/)[0]
      if (SKIP[baseCmd]) return

      // Delegate to RTK. Use ctx.signal if available (official pi), omit otherwise (oh-my-pi).
      const rewritten = await rewriteCommand(pi, cmd, ctx?.signal)
      if (rewritten && rewritten !== cmd) {
        event.input.command = rewritten
      }
    } catch (err) {
      // Fail open: never block execution on an unexpected error.
      console.warn("[rtk] unexpected error in tool_call handler; passing through command", err)
      return
    }
  })
}