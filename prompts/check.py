#!/usr/bin/env python3
"""check.py — 准确性测试。

验证 out/ 下 build.py 生成的文件与 golden/ 基线逐字节一致。
"准确"的定义：所有文件零 diff。任何差异都意味着模板/配置有 bug。

用法:
    python3 check.py            # 全量对比，打印差异摘要
    python3 check.py <name>     # 只看某个文件（如 pi），打印完整 diff

退出码 0 = 全部零 diff（模板精确）；1 = 有差异或 out 缺失。
"""
import difflib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GOLDEN = ROOT / "golden"
OUT = ROOT / "out"


def compare(name: str, full: bool = False) -> tuple[bool, list[str]]:
    """返回 (是否一致, diff 行列表)。"""
    g = GOLDEN / name
    o = OUT / name
    if not o.exists():
        return False, [f"[out/{name} 缺失]\n"]
    g_text = g.read_text(encoding="utf-8")
    o_text = o.read_text(encoding="utf-8")
    if g_text == o_text:
        return True, []
    diff = list(difflib.unified_diff(
        g_text.splitlines(keepends=True),
        o_text.splitlines(keepends=True),
        fromfile=f"golden/{name}",
        tofile=f"out/{name}",
        n=1,
    ))
    return False, diff


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    goldens = sorted(GOLDEN.glob("*.md"))
    if not goldens:
        print("✗ golden/ 无基线文件")
        return 1

    # 单文件模式：打印完整 diff
    if args:
        for name in args:
            name = name if name.endswith(".md") else name + ".md"
            ok, diff = compare(name, full=True)
            if ok:
                print(f"✓ {name} 零 diff")
            else:
                print(f"✗ {name} — 完整 diff:")
                print(''.join(diff), end="")
        return 0

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
    print(f"\n{bar}\n全部 {total} 个文件零 diff — 模板精确复现 golden。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
