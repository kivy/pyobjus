#!/usr/bin/env python3
"""Run examples that do not need a window or a network session.

Exits non-zero when an example raises. Skipped scripts are printed so a
new example is not silent: add it here only when it cannot run headless,
or when it is blocked on a known bug.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLES = ROOT / "examples"

# Needs a window, a Kivy app, or a live transfer.
SKIP = {
    "ns_alert.py": "opens a modal AppKit dialog",
    "background_transfer.py": "Kivy app that starts a background transfer",
    "delegate.py": "Kivy app; the delegate path is covered by tests/test_delegate.py",
    "osx_ios_sysinfo.py": "Kivy/plyer GUI, and UIDevice is an iOS class",
}


def main():
    failed = []
    for script in sorted(EXAMPLES.glob("*.py")):
        reason = SKIP.get(script.name)
        if reason:
            print(f"SKIP {script.name}: {reason}")
            continue
        print(f"RUN  {script.name}", flush=True)
        result = subprocess.run([sys.executable, str(script)], cwd=EXAMPLES)
        if result.returncode != 0:
            failed.append(script.name)
            print(f"FAIL {script.name}")
        else:
            print(f"OK   {script.name}")
    if failed:
        print("Failed examples: " + ", ".join(failed), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
