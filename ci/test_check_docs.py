#!/usr/bin/env python3

import importlib.util
import tempfile
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "check_docs", Path(__file__).with_name("check-docs.py")
)
check_docs = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(check_docs)


FRONTMATTER = """---
owner: docs-team
last-verified: 2026-07-19
freshness: 90d
---
"""


class CheckDocsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        (self.root / "ci").mkdir()
        (self.root / "docs" / "plans").mkdir(parents=True)
        (self.root / "docs" / "reference").mkdir()
        self.write(
            "ci/docs-frontmatter-exempt.txt",
            "# 文書改訂時に frontmatter 付与し本リストから除去\n",
        )

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, relative, text):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def errors(self):
        return check_docs.check(self.root)

    def test_valid_frontmatter_and_links_pass(self):
        self.write("README.md", "[Guide](docs/reference/guide.md)\n")
        self.write("docs/plans/plan.md", FRONTMATTER + "\n# Plan\n")
        self.write(
            "docs/reference/guide.md",
            FRONTMATTER
            + "\n[Plan][plan]\n[plan]: ../plans/plan.md#plan\n"
            + "[External](https://example.com)\n",
        )

        self.assertEqual(self.errors(), [])

    def test_missing_frontmatter_fails(self):
        self.write("README.md", "")
        self.write("docs/reference/guide.md", "# Guide\n")

        self.assertTrue(any("frontmatter is required" in error for error in self.errors()))

    def test_invalid_field_formats_fail(self):
        self.write("README.md", "")
        invalid = {
            "owner": FRONTMATTER.replace("owner: docs-team", "owner: []"),
            "last-verified": FRONTMATTER.replace("2026-07-19", "2026-02-30"),
            "freshness": FRONTMATTER.replace("90d", "90 days"),
        }
        for field, frontmatter in invalid.items():
            with self.subTest(field=field):
                self.write("docs/reference/guide.md", frontmatter + "\n# Guide\n")
                self.assertTrue(any(field in error for error in self.errors()))

    def test_broken_relative_link_fails(self):
        self.write("README.md", "[Missing](docs/reference/missing.md)\n")
        self.write("docs/reference/guide.md", FRONTMATTER + "\n# Guide\n")

        self.assertTrue(any("link target does not exist" in error for error in self.errors()))

    def test_exemption_skips_only_frontmatter(self):
        self.write("README.md", "")
        self.write(
            "ci/docs-frontmatter-exempt.txt",
            "# 文書改訂時に frontmatter 付与し本リストから除去\n"
            "docs/plans/protected.md\n",
        )
        self.write("docs/reference/guide.md", FRONTMATTER + "\n# Guide\n")
        self.write("docs/plans/protected.md", "[Guide](../reference/guide.md)\n")
        self.assertEqual(self.errors(), [])

        self.write("docs/plans/protected.md", "[Missing](../reference/missing.md)\n")
        self.assertTrue(any("link target does not exist" in error for error in self.errors()))


if __name__ == "__main__":
    unittest.main()
