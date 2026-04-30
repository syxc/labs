# Autoresearch for Claude Code

Claude Code 版本的 [pi-autoresearch](https://github.com/davebcn87/pi-autoresearch) — 自主实验循环，用于任何可度量目标的迭代优化。

## 安装

```bash
cp -r tools/autoresearch ~/.claude/skills/
cp tools/autoresearch/slash-command.md ~/.claude/commands/autoresearch.md
chmod +x ~/.claude/skills/autoresearch/scripts/*.sh
```

依赖：`git`, `jq`, `python3`, `bc`

## 用法

`/autoresearch` 后面跟任意文字作为目标描述（不是固定格式），或使用以下子命令：

```
/autoresearch reduce bundle size below 200kb    # 以该描述为 goal 启动新会话
/autoresearch                                    # 恢复已有会话
/autoresearch dashboard                          # 显示实验面板
/autoresearch finalize                           # 拆分为独立分支
/autoresearch clear                              # 清理所有状态
```

## 工作流程

### Setup

Agent 引导你提供 5 项信息，然后创建 `autoresearch.md`（会话计划）和 `autoresearch.sh`（benchmark 脚本）：

- **Goal** — 优化什么
- **Command** — 怎么跑 benchmark
- **Metric** — 指标名称 + 单位 + 方向（lower/higher is better）
- **Files in scope** — 可修改的文件
- **Constraints** — 硬约束（测试必须通过、不加依赖等）

### Loop

```
hypothesis → modify code → run benchmark → measure metric → keep or discard → repeat
```

- `keep` → git commit
- `discard`/`crash` → git revert
- 所有实验记录到 `autoresearch.jsonl`

### Confidence Score

基于 MAD（Median Absolute Deviation），衡量改进是否真实：

| 分数 | 含义 |
|------|------|
| ≥ 2.0× | 真实改进 |
| 1.0–2.0× | 噪声范围内，考虑重跑确认 |
| < 1.0× | 低于噪声底线 |

## 项目文件

```
autoresearch.md              # 会话计划（目标/指标/约束/实验历史）
autoresearch.sh              # Benchmark 脚本，输出 METRIC name=value 行
autoresearch.jsonl           # 实验记录
autoresearch.checks.sh       # 可选：正确性校验
autoresearch.ideas.md        # 可选：待尝试的优化点
autoresearch.config.json     # 可选：{ "maxIterations": 50, "workingDir": "/path" }
autoresearch.hooks/          # 可选：迭代钩子
    before.sh                # 每轮前触发
    after.sh                 # 每轮后触发
```

### Benchmark 脚本规范

`autoresearch.sh` 必须输出 `METRIC name=value` 行：

```bash
#!/bin/bash
set -euo pipefail
# ... run your benchmark ...
echo "METRIC total_ms=42.5"
echo "METRIC compile_us=1200"
```

## Hooks

将脚本放到 `autoresearch.hooks/`，自动在每轮迭代边界触发：

- `before.sh` — 实验前：搜索、反思、防震荡
- `after.sh` — 实验后：通知、日志、tag

Stdin 接收 JSON（session 快照），Stdout（≤8KB）作为 steer message 返回给 agent。30s 超时。

内置示例：

| Hook | 用途 |
|------|------|
| `before/hypothesis-reflection.sh` | 反思上一轮假设，检测连续 discard |
| `before/external-search.sh` | 每 10 轮搜索外部优化方案 |
| `after/auto-tag-winners.sh` | 给最佳结果的 git commit 打 tag |
| `after/macos-notify.sh` | macOS 通知新的最佳指标 |
| `after/learnings-journal.sh` | 结构化学习日志 |

## 测试

```bash
bash tests/e2e-test.sh              # 25 个断言，mock 数据，秒级完成
bash tests/real-world-python.sh     # 5 轮真实 Python 优化实验
```

## 与 pi-autoresearch 的差异

| 能力 | pi-autoresearch | Claude Code |
|------|----------------|-------------|
| 工具注册 | 原生 TypeScript extension | Bash scripts + SKILL.md |
| Git 操作 | 自动 | Agent 手动执行 |
| Dashboard | TUI inline widget | ASCII 表格 |
| Context 恢复 | Extension 自动注入 | `/autoresearch` 重新进入 |
| Hooks | Extension hooks | `hooks.sh`（30s, 8KB cap） |
| Confidence | MAD | 相同算法 |

## License

MIT
