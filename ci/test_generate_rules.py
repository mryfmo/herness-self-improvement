#!/usr/bin/env python3

import hashlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "generate_rules", Path(__file__).with_name("generate-rules.py")
)
generate_rules = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generate_rules)


SOURCE = """<!-- COMMON -->
Common rule.
<!-- CLAUDE -->
Claude-only rule.
<!-- AGENTS -->
Agents-only rule.
"""


class GenerateRulesTest(unittest.TestCase):
    def test_sections_are_target_specific(self):
        claude = generate_rules.render(SOURCE, "CLAUDE.md")
        agents = generate_rules.render(SOURCE, "AGENTS.md")

        self.assertIn("Common rule.", claude)
        self.assertIn("Claude-only rule.", claude)
        self.assertNotIn("Agents-only rule.", claude)
        self.assertIn("Common rule.", agents)
        self.assertIn("Agents-only rule.", agents)
        self.assertNotIn("Claude-only rule.", agents)

    def test_header_contains_source_hash(self):
        rendered = generate_rules.render(SOURCE, "CLAUDE.md")

        self.assertTrue(rendered.startswith("<!-- GENERATED FILE — edit rules.src.md -->"))
        self.assertIn(hashlib.sha256(SOURCE.encode()).hexdigest(), rendered.splitlines()[1])

    def test_all_three_markers_are_required(self):
        with self.assertRaises(ValueError):
            generate_rules.render(SOURCE.replace("<!-- AGENTS -->", ""), "AGENTS.md")

    def test_generation_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "rules.src.md").write_text(SOURCE)

            generate_rules.generate(root)
            first = {
                name: (root / name).read_text()
                for name in ("CLAUDE.md", "AGENTS.md")
            }
            generate_rules.generate(root)

            self.assertEqual(
                first,
                {
                    name: (root / name).read_text()
                    for name in ("CLAUDE.md", "AGENTS.md")
                },
            )

    def test_line_limit_emits_warning_without_failing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            short = root / "short.md"
            long = root / "long.md"
            short.write_text("line\n" * 120)
            long.write_text("line\n" * 121)
            output = io.StringIO()

            generate_rules.warn_long_files((short, long), output=output)

            self.assertNotIn("short.md", output.getvalue())
            self.assertIn("::warning file=", output.getvalue())
            self.assertIn("long.md has 121 lines; limit is 120", output.getvalue())


if __name__ == "__main__":
    unittest.main()
