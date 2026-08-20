#!/usr/bin/env python3
"""build.py — 从 core.md + agents/*.toml + snippets/ 生成各 agent 全局提示词。

渲染模型:
  - core.md 是主干模板，含 {{VAR}} 占位符。
  - 每个 agent 的 toml 声明各占位符的值。
  - 值为字面字符串，或 "snippet:NAME"（读 snippets/NAME.md 并 strip）。
  - 空值: 删除独占该行的占位符（整行含换行），不留多余空行。
  - 非空值: 替换占位符（多行值展开）。内联占位符（句子中间）同样替换。
  - 最后压缩 3+ 连续换行为 2，清理首部空行，确保以单个换行结尾。

用法:
    python3 build.py           # 生成全部到 out/
    python3 build.py pi omp    # 只生成指定 agent
"""
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CORE = (ROOT / "core.md").read_text(encoding="utf-8")
AGENTS_DIR = ROOT / "agents"
SNIPPETS = ROOT / "snippets"
OUT = ROOT / "out"

MULTI_BLANK = re.compile(r"\n{3,}")
PLACEHOLDERS = set(re.findall(r"\{\{([A-Z][A-Z0-9_]*)\}\}", CORE))


def resolve(value):
    """字面值原样返回；'snippet:NAME' 读 snippets/NAME.md 并 strip。"""
    if isinstance(value, str) and value.startswith("snippet:"):
        return (SNIPPETS / f"{value[len('snippet:'):]}.md").read_text(encoding="utf-8").strip()
    return value if isinstance(value, str) else str(value)


def render(toml_path: Path) -> str:
    cfg = tomllib.loads(toml_path.read_text(encoding="utf-8"))
    required = PLACEHOLDERS | {"output"}
    missing = sorted(required - cfg.keys())
    unknown = sorted(cfg.keys() - required)
    if missing:
        raise ValueError(f"缺少配置项: {', '.join(missing)}")
    if unknown:
        raise ValueError(f"未知配置项: {', '.join(unknown)}")
    if any(not isinstance(value, str) for value in cfg.values()):
        raise ValueError("所有配置值必须是字符串")

    text = CORE
    for var, raw in cfg.items():
        if var == "output":
            continue
        value = resolve(raw)
        if value == "":
            # 删独占行占位符（整行 + 换行）；内联占位符不匹配此正则，留待下面 replace
            text = re.sub(rf"(?m)^[ \t]*\{{\{{{var}\}}\}}[ \t]*\n?", "", text)
        if f"{{{{{var}}}}}" in text:
            text = text.replace(f"{{{{{var}}}}}", value)
    text = MULTI_BLANK.sub("\n\n", text)
    text = text.strip("\n") + "\n"
    unresolved = sorted(set(re.findall(r"\{\{([^{}]+)\}\}", text)))
    if unresolved:
        raise ValueError(f"存在未解析占位符: {', '.join(unresolved)}")
    return text


def main() -> int:
    targets = [a for a in sys.argv[1:] if not a.startswith("-")]
    agent_files = sorted(AGENTS_DIR.glob("*.toml"))
    if targets:
        known = {a.stem for a in agent_files}
        unknown = sorted(set(targets) - known)
        if unknown:
            print(f"✗ 未知 agent: {', '.join(unknown)}")
            return 1
        agent_files = [a for a in agent_files if a.stem in targets]
    if not agent_files:
        print("✗ 无匹配的 agent 配置（agents/*.toml）")
        return 1

    OUT.mkdir(exist_ok=True)
    failed = []
    for af in agent_files:
        name = af.stem
        try:
            content = render(af)
        except (OSError, ValueError) as e:
            print(f"✗ {name}: {e}")
            failed.append(name)
            continue
        (OUT / f"{name}.md").write_text(content, encoding="utf-8")
        print(f"✓ 生成 out/{name}.md ({len(content.encode('utf-8'))} 字节)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
