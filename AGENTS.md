# AGENTS.md

Guidance for AI coding agents working in this repository.

## Repository

Personal collection of tools, scripts, AI agent extensions, and prompt templates. No build system, no centralized dependencies — each sub-project runs independently.

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
