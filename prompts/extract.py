#!/usr/bin/env python3
"""extract.py — 从 golden/ 基线精确切片出当前使用的 snippet。

仅提取生成配置正在引用的差异片段；平台专属片段保留手工维护。
幂等：重复运行覆盖相同结果。
"""
import pathlib
import re

G = pathlib.Path(__file__).resolve().parent / "golden"
S = pathlib.Path(__file__).resolve().parent / "snippets"
S.mkdir(exist_ok=True)


def read(name: str) -> str:
    return (G / name).read_text(encoding="utf-8")


def write(name: str, content: str) -> None:
    (S / name).write_text(content.strip() + "\n", encoding="utf-8")


def slice_between(text: str, start: str, end: str) -> str:
    offset = text.index(start)
    return text[offset:text.index(end, offset)]


def retention(text: str) -> str:
    return re.search(r"### 保留项\n\n(.+?)\n\n(?:##|###)", text, re.DOTALL).group(1)


claude = read("claude.md")
codebuddy = read("codebuddy.md")
omp = read("omp.md")
opencode = read("opencode.md")
qwen = read("qwen.md")

# 保留项
write("retention_std.md", retention(claude))
write("retention_mid.md", retention(omp))
write("retention_strict.md", retention(qwen))

# 上下文管理
for agent in ("claude", "codebuddy", "pi", "opencode"):
    write(
        f"context_mgmt_{agent}.md",
        slice_between(read(f"{agent}.md"), "## 上下文管理", "## 工作流程"),
    )

# 工作流程、Git 与编码规范
write("workflow_pre_claude.md", slice_between(codebuddy, "### 修改前置", "### Git"))
write("workflow_pre_zcode.md", slice_between(omp, "### 修改前置", "### Git"))
write("git_claude_src.md", slice_between(claude, "### Git", "## 编码规范"))
write("git_claude.md", slice_between(codebuddy, "### Git", "## 编码规范"))
write("git_zcode.md", slice_between(omp, "### Git", "## 编码规范"))
write("git_qwen.md", slice_between(qwen, "### Git", "## 编码规范"))
write("coding_claude.md", slice_between(codebuddy, "## 编码规范", "## 工具"))
write("coding_zcode.md", slice_between(omp, "## 编码规范", "## 工具"))

# 不支持 @ 引用的平台内联工具命令
write("commands_a.md", codebuddy[codebuddy.index("### 命令参考") :])
write("commands_c.md", qwen[qwen.index("### 命令参考") :])

# 平台专属尾部
write("context_mode.md", opencode[opencode.index("### context-mode") :])
write("rtk_tail.md", "---\n\n@RTK.md")

print("✓ 已从 golden 提取当前使用的 snippet 到 snippets/")
