# Agent Prompts 同步系统

把 CLAUDE.md 与 7 个 AI agent 的全局提示词（pi / codebuddy / opencode / omp / qwen / craft-agent / factory）从**单一模板 + 配置**生成，避免手工同步近重复文件。以 `.claude/CLAUDE.md` 和 `.codex/AGENTS.md` 终稿为理念基准。

## 为什么需要这个

7 个 agent 共享约 80% 内容（元规则/输出规范/编码规范等），差异是结构化的（产品名、术语、include 机制、特有章节）。手工同步成本随文件数线性增长，且易漏。本系统把公共部分抽成模板，差异参数化，一次改动自动传播。

**为什么不用 `@include`**：codebuddy / opencode / qwen 不解析 `@` 引用，运行时拼装不可行。只能构建期生成扁平 md。

## 目录结构

```
prompts/
├── core.md              # 主干模板，含 {{VAR}} 占位符
├── agents/*.toml        # 每个 agent 的差异配置
├── snippets/*.md        # 差异片段（从 golden 提取）
├── golden/*.md          # 冻结基线（已知正确的 8 份文件：claude + 7 agent）
├── out/                 # build.py 生成产物（暂存，不直接部署）
├── build.py             # 渲染：core + config + snippets → out/
├── check.py             # 准确性测试：out/ 必须逐字节 == golden/
├── extract.py           # 从 golden 提取 snippet（golden 升级后重跑）
└── README.md
```

## 工作原理

`build.py` 读 `core.md`，对每个 agent 的 toml：
- `{{VAR}}` 替换为 toml 声明的值
- 值为 `snippet:NAME` → 读 `snippets/NAME.md`
- 值为 `""` → 删除该占位符所在行
- 最后压缩多余空行，输出到 `out/<name>.md`

`check.py` 对每个文件 `diff golden/<name>.md out/<name>.md`，**全部零 diff 才算通过**。

## 用法

```bash
python3 build.py           # 生成全部到 out/
python3 build.py pi omp    # 只生成指定 agent
python3 check.py           # 全量验证零 diff（退出码 0 = 通过）
python3 check.py pi        # 看某文件完整 diff
python3 extract.py         # golden 变更后，重新提取 snippet
```

## 日常维护场景

**改一条公共规则**（所有 agent 都要的）：
1. 改 `core.md` 对应处
2. `python3 build.py && python3 check.py`
3. check 显示哪些文件变了、变了几行；确认符合预期
4. 把 `out/` 部署到各 agent 目录（见各 toml 的 `output`）

**某 agent 加专属规则**：
1. 改它的 `agents/<name>.toml` 或对应 `snippets/`
2. build + check

**手工优化了某 agent 文件**（golden 升级）：
1. `cp` 新版到 `golden/<name>.md`
2. `python3 extract.py`（重新提取受影响的 snippet）
3. 必要时调整 `core.md` 或该 agent toml
4. build + check 到零 diff

## 准确性保证

`golden/` 是冻结基线（sha256 已记录）。`check.py` 要求生成结果**逐字节复现** golden——任何模板/配置错误都以 diff 暴露，不会 silently 错。这是可重复的回归测试：以后改 core，check 立刻显示影响。

**部署纪律**：`build.py` 只写 `out/`（暂存），不直接覆盖各 agent 目录。零 diff 通过后，才手动把 `out/` 拷到实际路径。

## 家族划分

三组 agent 共享家族片段（git / coding / workflow_pre 各有版本）：

| 家族 | agent | Git | Coding | Workflow |
|---|---|---|---|---|
| claude 派生 | codebuddy / pi / opencode | git_claude | coding_claude | workflow_pre_claude |
| zcode 派生 | omp / craft-agent | git_zcode | coding_zcode | workflow_pre_zcode |
| qwen 派生 | qwen / factory | git_qwen | coding_zcode | workflow_pre_zcode |

其他差异（产品名/header/上下文管理/answer 格式/retention 措辞/commands/@RTK/context-mode/开门见门）按 agent 单独配置。

## 范围

覆盖 CLAUDE.md 与 7 个"派生"agent，共 8 份。CLAUDE.md 已纳入（2026-08-14）：`golden/claude.md` 由 build 逐字节复现，差异走 `git_claude_src`（保留 CLAUDE 原版 "hooks" 措辞）与 `context_mgmt_claude`（progress.md 版上下文）两个 snippet。

基准 2 份保持手工独立：`.codex/AGENTS.md`（Sol/Terra/Luna 多代理段 + core.md 硬编码区差异，纳入需先参数化 core）、`.zcode/AGENTS.md`（ponytail 章节独有）。
