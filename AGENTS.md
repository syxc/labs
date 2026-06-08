# AGENTS.md

Guidance for AI coding agents working in this repository.

## Repository

Personal collection of tools, scripts, AI agent extensions, and prompt templates. No build system, no centralized dependencies — each sub-project runs independently.

## Commit Convention

```
<scope>: <summary>
```

- **scope** REQUIRED — infer from changed file paths + `git log --oneline -50`
- **summary** imperative mood, ≤72 chars, no trailing period, first word must be a verb
- NO type prefix (`feat`, `fix`, `chore`, etc.) — earlier commits may still use them, but new commits must not
- NO literal escape sequences (`\n`, `\t`) — use actual newlines/indentation
- NO Co-Authored-By, Signed-off-by, BREAKING CHANGE footers
- One commit = one logical change

## Sub-projects

### `skills/` — Agent Prompt Templates

Each skill is a self-contained directory: `skills/<name>/SKILL.md` (YAML frontmatter + prompt body).

**Existing skills:**
- `commit` — generate git commits following the convention above
- `review` — structured code review (correctness, regressions, edge cases, tests, security, performance)

**Adding a new skill:**
1. Create `skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`)
2. Register in `skills/README.md` Skill 列表 table

### `tools/cc-switch/` — Claude Code Provider Switcher

One-command switch between API providers (MiMo, GLM, DeepSeek, etc.). Shell script + `providers.json` config.

### `tools/autoresearch/` — Autonomous Experiment Loop

Claude Code skill for iterative optimization with metric tracking, git-backed keep/discard, confidence scoring, and hooks.

### `ai-builders-digest/` — AI Builders Morning Briefing

```bash
./ai-builders-digest/run-digest.sh              # fetch feed → generate LLM prompt
./ai-builders-digest/run-digest.sh --fetch-only  # fetch feed only
```

Output: `~/.follow-builders/`. Requires: `jq`, `python3`.

Key files: `config.json` (language/timezone/frequency), `prompts/digest-morning-briefing.md` (prompt template), `scheduled-task-prompt.md` (scheduled task backup).

### `pi/agent/extensions/` — pi Coding Agent Extensions

Extensions for [pi coding agent](https://github.com/earendil-works/pi/tree/main/packages/coding-agent).

- `claude-rules.ts` — loads `.claude/rules/*.md` (user + project level, path-scoped support)
- `rtk-integration.ts` — auto-rewrites bash tool calls via [RTK](https://github.com/rtk-ai/rtk) for 40-90% token savings
