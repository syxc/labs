#!/usr/bin/env python3
"""提示词构建与检查脚本的回归测试。"""
import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import build
import check


class PromptToolTests(unittest.TestCase):
    def test_build_failure_returns_nonzero(self):
        with tempfile.TemporaryDirectory() as tmp:
            with (
                mock.patch.object(build, "SNIPPETS", Path(tmp) / "missing"),
                mock.patch.object(build, "OUT", Path(tmp) / "out"),
                mock.patch.object(sys, "argv", ["build.py", "claude"]),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(build.main(), 1)

    def test_unresolved_placeholder_is_rejected(self):
        with mock.patch.object(build, "resolve", return_value="{{BROKEN}}"):
            with self.assertRaisesRegex(ValueError, "未解析占位符"):
                build.render(build.AGENTS_DIR / "claude.toml")

    def test_single_file_failure_returns_nonzero(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            agents = root / "agents"
            golden = root / "golden"
            out = root / "out"
            for directory in (agents, golden, out):
                directory.mkdir()
            (agents / "pi.toml").write_text('output = "/missing"\n', encoding="utf-8")
            (golden / "baseline.md").write_text("baseline\n", encoding="utf-8")

            with (
                mock.patch.object(check, "AGENTS", agents),
                mock.patch.object(check, "GOLDEN", golden),
                mock.patch.object(check, "OUT", out),
                mock.patch.object(sys, "argv", ["check.py", "pi"]),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(check.main(), 1)


if __name__ == "__main__":
    unittest.main()
