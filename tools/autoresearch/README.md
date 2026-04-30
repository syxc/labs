# Autoresearch for Claude Code

Claude Code 版本的 [pi-autoresearch](https://github.com/davebcn87/pi-autoresearch) — 自主实验循环，用于任何可度量目标的迭代优化。

## 功能

- **自主迭代循环**：设定目标后永不停止，持续实验直到中断或达到迭代上限
- **JSONL 状态持久化**：所有实验记录在 `autoresearch.jsonl`，跨 context 不会丢失
- **Git 自动管理**：keep 自动 commit，discard/crash 自动 revert
- **Confidence score**：基于 MAD（Median Absolute Deviation）的置信度评分
- **Before/After hooks**：迭代前后的自定义脚本（通知、学习日志、反震荡等）
- **ASCII Dashboard**：实验进度可视化面板
- **Checks 集成**：可选的正确性校验（测试/lint/类型检查）

## 安装

```bash
# 复制 skill 到 Claude Code skills 目录
cp -r tools/autoresearch ~/.claude/skills/

# 复制 slash command（可选，提供 /autoresearch 入口）
cp tools/autoresearch/slash-command.md ~/.claude/commands/autoresearch.md

# 确保脚本可执行
chmod +x ~/.claude/skills/autoresearch/scripts/*.sh
chmod +x ~/.claude/skills/autoresearch/references/hook-examples/**/*.sh
```

依赖：`git`, `jq`, `python3`, `bc`

## 使用

在 Claude Code 中：

```
# 新建实验会话
/autoresearch optimize unit test execution time

# 恢复已有会话（如果 autoresearch.md 存在）
/autoresearch

# 查看面板
/autoresearch dashboard

# 清理
/autoresearch clear
```

## 工作流程

### 1. Setup

Agent 会引导你提供：

- **Goal** — 优化什么？
- **Command** — 怎么跑 benchmark？
- **Metric** — 度量指标名称 + 单位 + 方向（lower/higher is better）
- **Files in scope** — 哪些文件可以改？
- **Constraints** — 硬约束（测试必须通过、不加依赖等）

然后创建 `autoresearch.md`（会话计划）、`autoresearch.sh`（benchmark 脚本）。

### 2. Loop

```
hypothesis → modify code → run benchmark → measure metric → keep or discard → repeat
```

- `keep` → git commit
- `discard`/`crash` → git revert
- 每次实验记录到 `autoresearch.jsonl`

### 3. Confidence Score

| 分数 | 含义 |
|------|------|
| ≥ 2.0× | 改进是真实的 |
| 1.0–2.0× | 在噪声范围内，考虑重跑 |
| < 1.0× | 低于噪声底线 |

### 4. Hooks（可选）

在 `autoresearch.hooks/` 放置脚本：

- `before.sh` — 每轮实验前触发（搜索、反思、防震荡）
- `after.sh` — 每轮实验后触发（通知、日志、tag）

内置示例：

| Hook | 用途 |
|------|------|
| `before/hypothesis-reflection.sh` | 反思上一轮假设，检测连续 discard |
| `before/external-search.sh` | 每 10 轮搜索外部优化方案 |
| `after/auto-tag-winners.sh` | 给最佳结果的 git commit 打 tag |
| `after/macos-notify.sh` | macOS 通知新的最佳指标 |
| `after/learnings-journal.sh` | 结构化学习日志 |

## 文件结构

```
your-project/
├── autoresearch.md              # 会话计划（目标/指标/约束/历史）
├── autoresearch.sh              # Benchmark 脚本
├── autoresearch.jsonl           # 实验记录（JSONL）
├── autoresearch.checks.sh       # 可选：正确性校验脚本
├── autoresearch.ideas.md        # 可选：待尝试的优化点
├── autoresearch.config.json     # 可选：配置（maxIterations, workingDir）
└── autoresearch.hooks/          # 可选：迭代钩子
    ├── before.sh
    └── after.sh
```

## Benchmark 脚本规范

`autoresearch.sh` 必须输出 `METRIC name=value` 行：

```bash
#!/bin/bash
set -euo pipefail
# ... run your benchmark ...
echo "METRIC total_ms=42.5"
echo "METRIC compile_us=1200"
```

## 与 pi-autoresearch 的差异

| 能力 | pi-autoresearch | Claude Code autoresearch |
|------|----------------|-------------------------|
| 工具注册 | 原生 TypeScript extension | Bash scripts + SKILL.md |
| Git 操作 | 自动 | Agent 在 SKILL.md 指导下手动执行 |
| Dashboard | TUI inline widget | ASCII 表格 |
| Context 恢复 | Extension 自动注入 | `/autoresearch` 重新进入 |
| Hooks | Extension hooks 系统 | `hooks.sh`（30s 超时, 8KB cap） |
| Confidence 算法 | MAD | 相同 |

## 测试

```bash
bash tests/e2e-test.sh
```

## License

MIT
