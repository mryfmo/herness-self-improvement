#!/usr/bin/env python3
"""Behavior tests for the interim skill scanner."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


SCANNER = Path(__file__).with_name("skill-scan.py")
FRONTMATTER = """---
name: example-skill
description: Exercise the scanner.
metadata:
  scope: project
  owner: test-team
  last-verified: 2026-07-19
  freshness: 90d
  provenance: self
---
"""


class SkillScanTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.skills = self.root / "skills"
        self.skills.mkdir()

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, relative: str, text: str) -> Path:
        path = self.skills / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def run_scan(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(SCANNER), str(self.skills)],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_valid_and_empty_directories_pass(self):
        folded = FRONTMATTER.replace(
            "description: Exercise the scanner.",
            "description: >\n  Exercise the scanner.",
        )
        self.write("example-skill/SKILL.md", folded + "\n# Example\n")
        result = self.run_scan()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("scanned 1 skill(s)", result.stdout)

        (self.skills / "example-skill" / "SKILL.md").unlink()
        result = self.run_scan()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("scanned 0 skill(s)", result.stdout)

    def test_missing_frontmatter_fails(self):
        self.write("example-skill/SKILL.md", "# Example\n")
        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("frontmatter is required", result.stderr)

        empty = FRONTMATTER.replace(
            "description: Exercise the scanner.",
            "description: >",
        )
        self.write("example-skill/SKILL.md", empty)
        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing frontmatter field description", result.stderr)

    def test_dynamic_context_fails(self):
        self.write("example-skill/SKILL.md", FRONTMATTER + "\n!`date`\n")
        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("dynamic context execution", result.stderr)

    def test_secret_fails_without_disclosure(self):
        secret = "gh" + "p_" + ("A" * 20)
        self.write("example-skill/SKILL.md", FRONTMATTER)
        self.write("example-skill/scripts/sample.txt", secret)
        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("secret pattern github_token", result.stderr)
        self.assertNotIn(secret, result.stderr)

    def test_secret_is_not_disclosed_as_network_destination(self):
        secret = "eyJ" + "A" * 8 + "." + "B" * 8 + "." + "C" * 8
        self.write("example-skill/SKILL.md", FRONTMATTER)
        self.write("example-skill/scripts/sample.txt", secret)

        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn(secret, result.stdout + result.stderr)

    def test_network_destinations_are_listed(self):
        self.write("example-skill/SKILL.md", FRONTMATTER)
        self.write(
            "example-skill/scripts/fetch.sh",
            "curl https://api.example.test/v1\n"
            "curl 10.0.0.8/private\n"
            "ssh user@2001:db8::1\n",
        )
        result = self.run_scan()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unknown-network api.example.test", result.stdout)
        self.assertIn("unknown-network 10.0.0.8", result.stdout)
        self.assertIn("unknown-network 2001:db8::1", result.stdout)

    def test_symlinked_skills_and_scripts_fail(self):
        outside_skill = self.root / "outside-SKILL.md"
        outside_skill.write_text(FRONTMATTER, encoding="utf-8")
        linked = self.skills / "linked"
        linked.mkdir()
        (linked / "SKILL.md").symlink_to(outside_skill)

        self.write("regular/SKILL.md", FRONTMATTER)
        outside_scripts = self.root / "outside-scripts"
        outside_scripts.mkdir()
        (self.skills / "regular" / "scripts").symlink_to(outside_scripts)

        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertGreaterEqual(result.stderr.count("symlink is not allowed"), 2)

    def test_non_utf8_bundled_file_fails_closed(self):
        self.write("example-skill/SKILL.md", FRONTMATTER)
        script = self.skills / "example-skill" / "scripts" / "sample.py"
        script.parent.mkdir()
        script.write_bytes(b"# coding: latin-1\nnote = '\xff'\n")

        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("bundled file must be UTF-8 text", result.stderr)

    def test_yaml_null_required_field_fails(self):
        invalid = FRONTMATTER.replace(
            "description: Exercise the scanner.",
            "description: null",
        )
        self.write("example-skill/SKILL.md", invalid)

        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing frontmatter field description", result.stderr)

        commented = FRONTMATTER.replace(
            "  owner: test-team",
            "  owner: # absent",
        )
        self.write("example-skill/SKILL.md", commented)
        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing frontmatter field metadata.owner", result.stderr)

    def test_unsupported_yaml_scalar_fails(self):
        invalid = FRONTMATTER.replace(
            "  provenance: self",
            "  provenance: self\n  malformed: [",
        )
        self.write("example-skill/SKILL.md", invalid)

        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("unsupported YAML scalar", result.stderr)

    def test_description_with_angle_brackets_fails(self):
        invalid = FRONTMATTER.replace(
            "description: Exercise the scanner.",
            "description: Exercise <scanner>.",
        )
        self.write("example-skill/SKILL.md", invalid)

        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("description cannot contain angle brackets", result.stderr)

    def test_frontmatter_delimiters_must_start_at_column_zero(self):
        indented_opening = FRONTMATTER.replace("---\n", " ---\n", 1)
        self.write("example-skill/SKILL.md", indented_opening)
        result = self.run_scan()
        self.assertEqual(result.returncode, 1)
        self.assertIn("frontmatter is required", result.stderr)

        literal = FRONTMATTER.replace(
            "description: Exercise the scanner.",
            "description: |\n  A separator follows.\n  ---\n  Still description.",
        )
        self.write("example-skill/SKILL.md", literal)
        result = self.run_scan()
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
