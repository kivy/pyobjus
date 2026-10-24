"""
Tests for load_framework.

On iOS, NSBundle.bundleWithPath_ returns a bundle for a system framework such
as WebKit, but the framework's binary lives only in the dyld shared cache, so
the bundle has no executable and load() returns NO. load_framework used to
return normally in that case, and the failure surfaced later as
"Unable to find class" from autoclass.

load_framework now opens the framework's binary with dlopen on iOS, and
raises elsewhere when NSBundle cannot load the framework, naming the dlopen
call to use (Python builds for iOS before 3.13 report sys.platform as
'darwin' and take that branch).

The iOS branch is exercised on macOS by patching sys.platform: dyld resolves
macOS system framework paths from the shared cache too. The NSBundle failure
is reproduced with a framework directory that has no binary.
"""
import os
import shutil
import sys
import tempfile
import unittest
from unittest import mock

import pytest


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS")
class TestLoadFrameworkNSBundle(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def test_loads_system_framework(self):
        from pyobjus.dylib_manager import INCLUDE, load_framework
        load_framework(INCLUDE.AppKit)

    def test_missing_path_raises(self):
        from pyobjus import ObjcException
        from pyobjus.dylib_manager import load_framework
        missing = os.path.join(self.tmp, "NoSuchKit.framework")
        with self.assertRaises(ObjcException):
            load_framework(missing)

    def test_bundle_without_binary_raises_and_suggests_dlopen(self):
        from pyobjus import ObjcException
        from pyobjus.dylib_manager import load_framework
        framework = os.path.join(self.tmp, "EmptyKit.framework")
        os.mkdir(framework)
        with self.assertRaises(ObjcException) as ctx:
            load_framework(framework)
        message = str(ctx.exception)
        self.assertIn("dlopen", message)
        self.assertIn(
            "ctypes.CDLL({0!r})".format(os.path.join(framework, "EmptyKit")),
            message)

    def test_trailing_slash_names_the_same_binary(self):
        from pyobjus import ObjcException
        from pyobjus.dylib_manager import load_framework
        framework = os.path.join(self.tmp, "EmptyKit.framework")
        os.mkdir(framework)
        with self.assertRaises(ObjcException) as ctx:
            load_framework(framework + "/")
        self.assertIn(
            "ctypes.CDLL({0!r})".format(os.path.join(framework, "EmptyKit")),
            str(ctx.exception))


@pytest.mark.skipif(sys.platform != "darwin", reason="Only for macOS")
class TestLoadFrameworkIOS(unittest.TestCase):

    def setUp(self):
        patcher = mock.patch("pyobjus.dylib_manager.sys.platform", "ios")
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_opens_binary_with_dlopen(self):
        from pyobjus.dylib_manager import load_framework
        import pyobjus.dylib_manager as dm
        with mock.patch.object(dm.ctypes, "CDLL") as cdll, \
                mock.patch.object(dm, "autoclass") as autoclass:
            load_framework("/System/Library/Frameworks/WebKit.framework/")
        cdll.assert_called_once_with(
            "/System/Library/Frameworks/WebKit.framework/WebKit")
        autoclass.assert_not_called()

    def test_loads_real_framework(self):
        from pyobjus.dylib_manager import INCLUDE, load_framework
        load_framework(INCLUDE.AppKit)

    def test_missing_framework_raises_with_dlopen_reason(self):
        from pyobjus import ObjcException
        from pyobjus.dylib_manager import load_framework
        with self.assertRaises(ObjcException) as ctx:
            load_framework("/System/Library/Frameworks/NoSuchKit.framework")
        message = str(ctx.exception)
        self.assertIn("NoSuchKit.framework", message)
        self.assertIn("NoSuchKit.framework/NoSuchKit", message)
