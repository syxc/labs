#!/usr/bin/env python3
"""extract.py — 从 golden/ 基线精确切片出所有 snippet。

确保 snippet 内容与 golden 逐字节一致（不靠记忆）。codebuddy 验证过的
手写 snippet（header_codebuddy/answer_example/retention_std/context_mgmt_codebuddy/
hooks_flow_claude/commands_a）保留不动，本脚本只生成其余片段。

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
    s = text.index(start)
    return text[s:text.index(end, s)]


# --- headers（注释头 = 开头到 ## 角色）---
for agent in ("pi", "opencode"):
    t = read(f"{agent}.md")
    write(f"header_{agent}.md", t[: t.index("## 角色")])

# --- answer_pattern「」版（从 omp 提取 <answer_pattern> 块）---
omp = read("omp.md")
m = re.search(r"<answer_pattern>.*?</answer_pattern>", omp, re.DOTALL)
write("answer_pattern.md", m.group(0))

# --- retention：mid（omp）/ strict（qwen）---
qw = read("qwen.md")
write("retention_mid.md", re.search(r"### 保留项\n\n(.+?)\n\n##", omp, re.DOTALL).group(1))
write("retention_strict.md", re.search(r"### 保留项\n\n(.+?)\n\n##", qw, re.DOTALL).group(1))

# --- context_mgmt（pi/opencode：## 上下文管理 → ## 工作流程）---
for agent in ("pi", "opencode"):
    write(f"context_mgmt_{agent}.md", slice_between(read(f"{agent}.md"), "## 上下文管理", "## 工作流程"))

# --- extra_answer_rule（开门见门，qwen/factory）---
write("extra_answer_rule.md", re.search(r"(- 开门见山[^\n]+)", qw).group(1))

# --- commands_c（qwen：### 命令参考 → 末尾）---
write("commands_c.md", qw[qw.index("### 命令参考") :])

# --- context_mode（opencode：### context-mode → 末尾）---
oc = read("opencode.md")
write("context_mode.md", oc[oc.index("### context-mode") :])

# --- workflow_pre（修改前置 → Git 前）：claude 风格 / zcode 风格 ---
write("workflow_pre_claude.md", slice_between(read("codebuddy.md"), "### 修改前置", "### Git"))
write("workflow_pre_zcode.md", slice_between(read("omp.md"), "### 修改前置", "### Git"))

# --- git / coding（家族 snippet，自包含，含各自的 hooks 规则）---
write("git_claude.md", slice_between(read("codebuddy.md"), "### Git", "## 编码规范"))
write("git_zcode.md", slice_between(read("omp.md"), "### Git", "## 编码规范"))
write("git_qwen.md", slice_between(read("qwen.md"), "### Git", "## 编码规范"))
write("coding_claude.md", slice_between(read("codebuddy.md"), "## 编码规范", "## 工具"))
write("coding_zcode.md", slice_between(read("omp.md"), "## 编码规范", "## 工具"))

# --- rtk_tail（固定文本）---
write("rtk_tail.md", "---\n\n@RTK.md")

print("✓ 已从 golden 提取全部 snippet 到 snippets/")
for f in sorted(S.glob("*.md")):
    print(f"  {f.name} ({f.stat().st_size} 字节)")
