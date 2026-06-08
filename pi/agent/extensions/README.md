# pi extensions

Extensions for [pi coding agent](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent).

## Extensions

### claude-rules

Implements Claude Code's `.claude/rules/` loading behavior for pi. Automatically discovers and loads rules from `~/.claude/rules/` and `.claude/rules/` directories.

**Features**:
- Auto-discovers all `.md` files recursively
- Unconditional rules load at session start
- Path-scoped rules (with `paths:` frontmatter) activate only when working with matching files
- User-level rules (`~/.claude/rules/`) load before project rules (`.claude/rules/`)
- Supports glob patterns: `**/*.ts`, `src/**/*`, `*.{ts,tsx}`

**Example rule with path-scope**:
```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
---

# TypeScript Rules
- Use strict mode
- No default exports, named exports only
```

**Install**:
```json
{ "extensions": ["~/.pi/agent/extensions/claude-rules.ts"] }
```

**Requires**: Create `~/.claude/rules/*.md` and/or `.claude/rules/*.md` with your rules.

---

### rtk-integration

Cross-platform command rewrite plugin for [RTK](https://github.com/rtk-ai/rtk) — 40-90% token savings on bash tool calls.

Compatible with both `@earendil-works/pi-coding-agent` and `@oh-my-pi/pi-coding-agent`. All rewrite logic lives in `rtk rewrite` (single source of truth in Rust). When rtk is unavailable or doesn't rewrite a command, output passes through unchanged — zero information loss, zero negative risk.

**Features**:
- Auto-rewrites `bash` tool calls via `rtk rewrite` with 2s timeout
- Status bar integration (shows `RTK ✓` on session start)
- Output-format-sensitive skip list (`ls`, `find` — preserves agent parsing assumptions)
- Fail-open: errors and timeouts pass through unchanged, never blocks execution
- `RTK_DISABLED=1` env var to disable without uninstalling

**Install**:
```bash
cp rtk-integration.ts ~/.pi/agent/extensions/
```

**Requires**:
```bash
brew install rtk  # v0.23+
```

## License

MIT
