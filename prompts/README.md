# Agent Prompts 同步系统

从一份共享模板生成 Claude 与 7 个 Agent 的全局提示词：CodeBuddy、Craft Agent、Factory、OMP、OpenCode、Pi、Qwen。公共规则以当前 `~/.claude/CLAUDE.md` 为基准，平台差异通过配置和片段保留。

Codex 与 Zcode 不在生成或部署范围内。`~/.codex/AGENTS.md` 包含 Codex 专属的模型与 Agent 编排，`~/.zcode/AGENTS.md` 包含 Zcode 专属规则，两者始终独立维护。

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
- `snippets/*.md`：上下文、Git、编码规范、RTK、context-mode 等差异片段
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

`build.py` 会校验配置项和占位符，任一 Agent 生成失败就返回非零。`check.py` 会核对 `agents/`、`golden/`、`out/` 的文件集合，并要求生成结果与基线逐字节一致。加上 `--deployed` 后，还会核对各 TOML 中 `output` 指向的实际文件。

## 同步规则

- Claude：生成结果必须与当前 `~/.claude/CLAUDE.md` 完全一致。
- 其他 Agent：继承 Claude 的公共原则和精简结构，不机械复制平台专属机制。
- CodeBuddy、Pi、OpenCode 保留各自的跨会话上下文措辞；生成文件不添加说明性 HTML 注释头。
- OpenCode 保留 context-mode 章节。
- Claude 使用原生 `@TOOLS.md` 和 `@RTK.md` 引用，加载同目录文件。
- CodeBuddy、Craft Agent、OpenCode、Pi、OMP 内联同一组工具命令，Qwen 与 Factory 使用更严格的命令版本。
- Pi、OMP、Factory 保留 `@RTK.md` 尾部作为兼容入口和规则提示。RTK 的实际命令改写依赖各客户端已配置的 hook 或 extension，不能只依赖这行文本。
- Qwen 与 Factory 保留更严格的 Git hooks 规则；其余 Agent 保留各自家族措辞。

## 更新流程

1. 修改 `core.md`、对应配置或片段。
2. 运行 `python3 build.py`，审查 `out/` 与现有 golden 的 diff。
3. 确认后将 `out/*.md` 更新为 `golden/*.md`。
4. 再运行 `python3 build.py && python3 check.py`。
5. 部署前备份 TOML 中 `output` 指向的实际文件，再复制生成结果。
6. 运行 `python3 check.py --deployed`，确认部署文件与生成结果一致。

构建和检查不会自动部署，也不会自动 commit 或 push。直接修改实际全局文件后，必须同步更新模板和对应 golden；`python3 check.py --deployed` 会报告尚未同步的部署文件。
