import os
import subprocess
import sys

import pytest

GUARD_MALLOC = "/usr/lib/libgmalloc.dylib"

requires_guard_malloc = pytest.mark.skipif(
    not os.path.exists(GUARD_MALLOC), reason="Guard Malloc is not installed")


def run_script(script, guard_malloc=False):
    """Run script in a fresh interpreter, optionally under Guard Malloc.

    Guard Malloc places each block against an unmapped page, so a heap
    overrun crashes instead of passing unnoticed.
    """
    env = dict(os.environ, DYLD_INSERT_LIBRARIES=GUARD_MALLOC) if guard_malloc else None
    return subprocess.run(
        [sys.executable, "-c", script],
        env=env, capture_output=True, text=True, timeout=120)


def assert_ran_ok(test_case, result):
    """The script exited 0 and printed "ok"."""
    test_case.assertEqual(
        result.returncode, 0,
        "exit status {}; stderr:\n{}".format(
            result.returncode, result.stderr[-2000:]))
    test_case.assertIn("ok", result.stdout)
