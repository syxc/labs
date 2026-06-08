# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## 项目概述

个人工具、脚本和 AI agent prompt 模板的集合。无构建系统，无依赖安装，纯 shell 脚本 + markdown。

## Commit 规范

格式：`<scope>: <summary>`
- scope 必填，从文件路径和 git log 推断
- summary 祈使句动词开头，≤72 字符，无尾部句号
- 禁止 type prefix（`feat`/`fix`/`chore` 等）
- 禁止转义字面量（`\n`、`\t`），用真实换行/缩进

## 目录结构

| 目录 | 用途 |
|------|------|
| `skills/` | AI agent prompt 模板（`<name>/SKILL.md`，YAML frontmatter + 正文） |
| `tools/cc-switch/` | Claude Code 多供应商切换（MiMo / GLM / DeepSeek） |
| `tools/autoresearch/` | Claude Code 自主实验循环 skill |
| `ai-builders-digest/` | AI Builders 早报生成（`run-digest.sh` 拉取 feed → LLM prompt） |

## Skills

每个 skill 是 `skills/<name>/SKILL.md`，通过 symlink 加载到 Claude Code：

```bash
ln -s $PWD/skills/<name> ~/.claude/skills/<name>
```

现有 skill：`commit`（commit 消息生成）、`review`（结构化代码审查）。

新增 skill 需在 `skills/README.md` 的 Skill 列表中注册。

## ai-builders-digest

```bash
./ai-builders-digest/run-digest.sh              # 拉取 feed → 生成 LLM prompt
./ai-builders-digest/run-digest.sh --fetch-only  # 仅拉取 feed
```

输出到 `~/.follow-builders/`，依赖 `jq`、`python3`。
