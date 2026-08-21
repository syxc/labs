#!/usr/bin/env python3
"""check.py — 生成结果与部署文件一致性测试。

验证 out/ 下 build.py 生成的文件与 golden/ 基线逐字节一致。
"准确"的定义：所有文件零 diff。任何差异都意味着模板/配置有 bug。

用法:
    python3 check.py            # 全量对比，打印差异摘要
    python3 check.py <name>     # 只看某个文件（如 pi），打印完整 diff
    python3 check.py --deployed # 同时核对实际文件和统一 TOOLS.md

退出码 0 = 全部零 diff（模板精确）；1 = 有差异或 out 缺失。
"""
import difflib
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOLDEN = ROOT / "golden"
OUT = ROOT / "out"
AGENTS = ROOT / "agents"
TOOLS = ROOT / "snippets" / "tools.md"


def compare(name: str) -> tuple[bool, list[str]]:
    """返回 (是否一致, diff 行列表)。"""
    g = GOLDEN / name
    o = OUT / name
    if not g.exists():
        return False, [f"[golden/{name} 缺失]\n"]
    if not o.exists():
        return False, [f"[out/{name} 缺失]\n"]
    g_bytes = g.read_bytes()
    o_bytes = o.read_bytes()
    if g_bytes == o_bytes:
        return True, []
    g_text = g_bytes.decode("utf-8")
    o_text = o_bytes.decode("utf-8")
    diff = list(difflib.unified_diff(
        g_text.splitlines(keepends=True),
        o_text.splitlines(keepends=True),
        fromfile=f"golden/{name}",
        tofile=f"out/{name}",
        n=1,
    ))
    return False, diff


def compare_deployed(name: str) -> tuple[bool, str]:
    stem = Path(name).stem
    config = AGENTS / f"{stem}.toml"
    if not config.exists():
        return False, f"agents/{stem}.toml 缺失"
    cfg = tomllib.loads(config.read_text(encoding="utf-8"))
    output = cfg.get("output")
    if not isinstance(output, str) or not output:
        return False, f"agents/{stem}.toml 缺少有效 output"
    generated = OUT / f"{stem}.md"
    deployed = Path(output).expanduser()
    if not generated.exists():
        return False, f"out/{stem}.md 缺失"
    if not deployed.exists():
        return False, f"{deployed} 缺失"
    if generated.read_bytes() != deployed.read_bytes():
        return False, f"{deployed} 与 out/{stem}.md 不一致"
    return True, str(deployed)


def compare_deployed_tools() -> tuple[bool, str]:
    config = AGENTS / "claude.toml"
    if not config.exists():
        return False, "agents/claude.toml 缺失"
    cfg = tomllib.loads(config.read_text(encoding="utf-8"))
    output = cfg.get("output")
    if not isinstance(output, str) or not output:
        return False, "agents/claude.toml 缺少有效 output"
    deployed = Path(output).expanduser().with_name("TOOLS.md")
    if not TOOLS.exists():
        return False, "snippets/tools.md 缺失"
    if not deployed.exists():
        return False, f"{deployed} 缺失"
    if TOOLS.read_bytes() != deployed.read_bytes():
        return False, f"{deployed} 与 snippets/tools.md 不一致"
    return True, str(deployed)


def main() -> int:
    check_deployed = "--deployed" in sys.argv[1:]
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    configs = sorted(AGENTS.glob("*.toml"))
    goldens = sorted(GOLDEN.glob("*.md"))
    outputs = sorted(OUT.glob("*.md"))
    if not configs or not goldens:
        print("✗ agents/ 或 golden/ 缺少基线文件")
        return 1

    configured = {f"{path.stem}.md" for path in configs}
    if not args:
        sets = {
            "agents": configured,
            "golden": {path.name for path in goldens},
            "out": {path.name for path in outputs},
        }
        if len({frozenset(names) for names in sets.values()}) != 1:
            for label, names in sets.items():
                print(f"✗ {label}: {', '.join(sorted(names)) or '(空)'}")
            return 1

    # 单文件模式：打印完整 diff
    if args:
        success = True
        check_tools = False
        for name in args:
            name = name if name.endswith(".md") else name + ".md"
            if name not in configured:
                print(f"✗ 未知 agent: {Path(name).stem}")
                success = False
                continue
            ok, diff = compare(name)
            if ok:
                print(f"✓ {name} 零 diff")
            else:
                print(f"✗ {name} — 完整 diff:")
                print(''.join(diff), end="")
                success = False
            if check_deployed:
                deployed_ok, detail = compare_deployed(name)
                print(f"{'✓' if deployed_ok else '✗'} {name} 部署: {detail}")
                success = success and deployed_ok
                check_tools = check_tools or name == "claude.md"
        if check_tools:
            tools_ok, tools_detail = compare_deployed_tools()
            print(f"{'✓' if tools_ok else '✗'} tools.md 部署: {tools_detail}")
            success = success and tools_ok
        return 0 if success else 1

    # 全量模式
    passed, failed = [], []
    for g in goldens:
        ok, diff = compare(g.name)
        (passed if ok else failed).append((g.name, diff))

    total = len(goldens)
    bar = "=" * 60
    print(f"\n{bar}\n准确度: {len(passed)}/{total} 个文件零 diff\n{bar}")
    if passed:
        print("✓ " + ", ".join(n for n, _ in passed))
    if failed:
        for name, diff in failed:
            changed = sum(1 for l in diff if l[:1] in "+-" and l[:3] not in ("+++", "---"))
            print(f"\n✗ {name} — {changed} 行差异（前 40 行）:")
            print(''.join(diff[:40]))
        print(f"{bar}\n失败 {len(failed)}/{total}：模板尚未精确复现 golden，继续修。")
        return 1

    if check_deployed:
        deployed_failed = []
        for name in sorted(configured):
            ok, detail = compare_deployed(name)
            print(f"{'✓' if ok else '✗'} {name} 部署: {detail}")
            if not ok:
                deployed_failed.append(name)
        tools_ok, tools_detail = compare_deployed_tools()
        print(f"{'✓' if tools_ok else '✗'} tools.md 部署: {tools_detail}")
        if not tools_ok:
            deployed_failed.append("tools.md")
        if deployed_failed:
            print(f"{bar}\n失败 {len(deployed_failed)} 个部署目标：部署文件与生成结果不一致。")
            return 1
    print(f"\n{bar}\n全部 {total} 个文件零 diff — 模板精确复现 golden。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
