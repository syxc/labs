# Agent Prompts 同步系统

从一份共享模板生成 Claude 与 9 个 Agent 的全局提示词：CodeBuddy、Codex、Craft Agent、Factory、OMP、OpenCode、Pi、Qwen、ZCode。公共规则以当前 `~/.claude/CLAUDE.md` 为基准，平台差异通过配置和片段保留。

Codex 已纳入同步：公共规则与 Claude 蓝本完全同源，仅保留平台必要差异（`output` 指向 `~/.codex/AGENTS.md`、工具节引用 Codex 专属 `TOOLS.md`、页脚 `@RTK.md` 使用绝对路径）。ZCode 同样纳入同步，但保留自身的内联工具规则，不照搬 Claude 专属引用。

## 目录

```
prompts/
├── core.md
├── agents/*.toml
├── snippets/*.md
├── golden/*.md
├── out/
├── build.py
├── check.py
├── extract.py
├── test_prompts.py
└── README.md
```

- `core.md`：公共规则和占位符
- `agents/*.toml`：输出路径、产品名和平台差异
- `snippets/*.md`：上下文、Git、编码规范、统一工具命令、RTK、context-mode 等片段
- `golden/*.md`：已确认的逐字节基线
- `out/*.md`：临时生成产物，不自动部署

## 使用

```bash
python3 build.py
python3 check.py
python3 build.py pi omp
python3 check.py pi
python3 check.py --deployed
python3 -m unittest -v test_prompts.py
python3 extract.py
```

`build.py` 会校验配置项和占位符，任一 Agent 生成失败就返回非零。`check.py` 会核对 `agents/`、`golden/`、`out/` 的文件集合，并要求生成结果与基线逐字节一致。加上 `--deployed` 后，还会核对各 TOML 中 `output` 指向的实际文件，以及 `~/.claude/TOOLS.md`。

`extract.py` 仅用于从 golden 反向重建可提取的 snippets，会覆盖对应片段；日常同步不需要运行。

## 同步规则

- Claude：生成结果必须与当前 `~/.claude/CLAUDE.md` 完全一致。
- 其他 Agent：继承 Claude 的公共原则和精简结构，不机械复制平台专属机制。
- CodeBuddy、Pi、OpenCode 保留各自的跨会话上下文措辞；生成文件不添加说明性 HTML 注释头。
- OpenCode 保留 context-mode 章节。
- `snippets/tools.md` 是工具命令的唯一来源。Claude 通过原生 `@TOOLS.md` 按需加载，其他 8 个 Agent 内联同一份内容。
- Pi、OMP、Factory 保留 `@RTK.md` 尾部作为兼容入口和规则提示。RTK 的实际命令改写依赖各客户端已配置的 hook 或 extension，不能只依赖这行文本。
- ZCode 不展开 `@import` 或 `@include`，因此不使用 Claude 的 `@TOOLS.md`、`@RTK.md` 引用；RTK 与 context-mode 由其插件提供。
- Qwen 与 Factory 保留更严格的 Git hooks 规则；其余 Agent 保留各自家族措辞。

## 更新流程

1. 修改 `core.md`、对应配置或片段。
2. 运行 `python3 build.py`，审查 `out/` 与现有 golden 的 diff。
3. 确认后将 `out/*.md` 更新为 `golden/*.md`。
4. 再运行 `python3 build.py && python3 check.py`。
5. 部署前备份 TOML 中 `output` 指向的实际文件和 `~/.claude/TOOLS.md`，再复制生成结果与统一工具命令。
6. 运行 `python3 check.py --deployed`，确认部署文件与生成结果一致。

构建和检查不会自动部署，也不会自动 commit 或 push。直接修改 `~/.claude/CLAUDE.md` 或 `~/.claude/TOOLS.md` 后，必须同步更新模板或 `snippets/tools.md` 并重建相关 Agent；`python3 check.py --deployed` 会报告尚未同步的部署文件。
