#!/usr/bin/env python3
"""Static course-governance checks. Never interprets a URL as proof of CI success."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / "docs/governance/CURRENT_STATE.md"
EVIDENCE = ROOT / "docs/stabilization/STABILIZATION_EVIDENCE_V1.md"


class GovernanceContinuityTests(unittest.TestCase):
    def test_authority_and_evidence_paths(self):
        self.assertTrue(STATE.is_file())
        self.assertTrue(EVIDENCE.is_file())
        text = STATE.read_text(encoding="utf-8")
        for token in ("Academy progress ledger", "runtime", "source-inspected", "systemd",
                      "docs", "scope", "merge", "evidence"):
            self.assertIn(token.lower(), text.lower())
        self.assertTrue((ROOT / "scripts/managed_process.py").is_file())
        self.assertTrue((ROOT / "scripts/test_managed_process.py").is_file())
        self.assertTrue((ROOT / ".github/workflows/process-safety.yml").is_file())

    def test_no_false_current_runtime_claim(self):
        text = STATE.read_text(encoding="utf-8").lower()
        self.assertIn("still unverified", text)
        for item in ("container pid1", "systemd", "kubernetes"):
            self.assertIn(item, text)
        self.assertIn("bounded jvm smoke", text)

    def test_historical_record_unchanged_semantics(self):
        evidence = EVIDENCE.read_text(encoding="utf-8")
        self.assertIn("935dc9707d4bb131e8e06d61bc2dbc721d85e415", evidence)
        self.assertIn("44800925965", evidence)
        self.assertIn("not Part 1.1.6", evidence)


if __name__ == "__main__":
    unittest.main()
