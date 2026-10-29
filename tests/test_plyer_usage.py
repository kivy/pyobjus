"""Plyer call shapes the rest of the suite does not cover.

Selectors from kivy/plyer master:

* https://github.com/kivy/plyer/blob/master/plyer/platforms/macosx/audio.py
* https://github.com/kivy/plyer/blob/master/plyer/platforms/ios/voip.py
* https://github.com/kivy/plyer/blob/master/plyer/platforms/macosx/filechooser.py
* https://github.com/kivy/plyer/blob/master/plyer/platforms/macosx/gps.py
* https://github.com/kivy/plyer/blob/master/plyer/platforms/ios/gps.py
* https://github.com/kivy/plyer/blob/master/plyer/platforms/macosx/notification.py
"""
import ctypes
import unittest

import pytest

pytest.importorskip('pyobjus')

from objc_msgsend import OBJC, msg_send
from pyobjus import (
    ObjcBOOL, ObjcClassInstance, ObjcException, ObjcMethod, autoclass,
    convert_py_to_nsobject, protocol)
from pyobjus.dylib_manager import INCLUDE, load_framework


def _require(name):
    """Return an ObjC class, or skip when this OS no longer has it.

    autoclass raises ObjcException ('Unable to find class ...') when the
    runtime has no such class. A missing class does not raise ValueError
    or AttributeError.
    """
    try:
        return autoclass(name)
    except ObjcException as exc:
        raise unittest.SkipTest('%s is unavailable: %s' % (name, exc))


def _responds(target, selector_name):
    selector = OBJC.sel_registerName(selector_name.encode('utf-8'))
    return msg_send(ctypes.c_ubyte, target, 'respondsToSelector:', selector)


def _assert_same_proxy(case, stored, delegate):
    """The getter and convert_py_to_nsobject share one ObjC object.

    ObjcClassInstance equality compares addresses, so a bare assertEqual
    only reports that two proxies differ. Compare the addresses and name
    the cache: one Python delegate has one proxy.
    """
    proxy = convert_py_to_nsobject(delegate)
    case.assertIsInstance(stored, ObjcClassInstance)
    case.assertIsInstance(proxy, ObjcClassInstance)
    case.assertEqual(
        stored.get_address(), proxy.get_address(),
        'delegate getter and convert_py_to_nsobject should return the same '
        'ObjC proxy for one Python delegate')


class _NotificationDelegate(object):
    def __init__(self):
        self.center = None
        self.notification = None

    @protocol('NSUserNotificationCenterDelegate')
    def userNotificationCenter_shouldPresentNotification_(
            self, center, notification):
        self.center = center
        self.notification = notification
        return ObjcBOOL(True)


class _LocationDelegate(object):
    def __init__(self):
        self.status = None
        self.locations = None

    @protocol('CLLocationManagerDelegate')
    def locationManager_didChangeAuthorizationStatus_(self, manager, status):
        self.status = status

    @protocol('CLLocationManagerDelegate')
    def locationManager_didUpdateLocations_(self, manager, locations):
        self.locations = locations


class PlyerUsageTest(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        load_framework(INCLUDE.Foundation)
        load_framework(INCLUDE.AppKit)
        load_framework(INCLUDE.AVFoundation)
        load_framework(INCLUDE.CoreLocation)

    def test_audio_format_mixes_int_double_and_bool(self):
        # commonFormat 1 is float32, 3 is int16.
        AVAudioFormat = _require('AVAudioFormat')
        interleaved = AVAudioFormat.alloc()
        interleaved = (
            interleaved
            .initWithCommonFormat_sampleRate_channels_interleaved_(
                1, 44100.0, 2, True))
        self.assertEqual(interleaved.sampleRate, 44100.0)
        self.assertEqual(interleaved.channelCount, 2)
        self.assertTrue(interleaved.isInterleaved())

        packed = AVAudioFormat.alloc()
        packed = packed.initWithCommonFormat_sampleRate_channels_interleaved_(
            3, 16000.0, 1, False)
        self.assertEqual(packed.sampleRate, 16000.0)
        self.assertEqual(packed.channelCount, 1)
        self.assertEqual(packed.commonFormat, 3)
        self.assertFalse(packed.isInterleaved())

    def test_python_str_is_accepted_as_nsstring(self):
        # filechooser passes a str to fileURLWithPath:. GPS passes a str as
        # the run-loop mode. Neither call goes through objc_str().
        url = autoclass('NSURL').fileURLWithPath_('/tmp')
        path = url.path.UTF8String()
        if isinstance(path, bytes):
            path = path.decode('utf-8')
        self.assertEqual(path, '/tmp')

        # runMode:beforeDate: returns false when the loop has no sources.
        # A port registered for that same mode string gives it one.
        run_loop = autoclass('NSRunLoop').currentRunLoop()
        port = autoclass('NSMachPort').alloc().init()
        run_loop.addPort_forMode_(port, 'NSDefaultRunLoopMode')
        self.addCleanup(
            run_loop.removePort_forMode_, port, 'NSDefaultRunLoopMode')
        until = autoclass('NSDate').dateWithTimeIntervalSinceNow_(0.01)
        self.assertTrue(
            run_loop.runMode_beforeDate_('NSDefaultRunLoopMode', until))

    def test_notification_delegate_returns_objcbool(self):
        # Returns ObjcBOOL(True) from the real delegate method. Not delivered.
        # None is an object argument, so setDelegate_(None) passes nil.
        NSUserNotification = _require('NSUserNotification')
        NSUserNotificationCenter = _require('NSUserNotificationCenter')
        notification = NSUserNotification.alloc().init()
        delegate = _NotificationDelegate()
        center = NSUserNotificationCenter.defaultUserNotificationCenter()
        if center is None:
            # nil on some systems, e.g. the macos-15-intel CI runners.
            self.skipTest('defaultUserNotificationCenter returned nil')
        center.setDelegate_(delegate)
        self.addCleanup(center.setDelegate_, None)

        # This getter is a method. CLLocationManager.delegate is a property.
        getter = center.delegate
        self.assertIsInstance(
            getter, ObjcMethod,
            'NSUserNotificationCenter.delegate is a method; call it')
        stored = getter()
        _assert_same_proxy(self, stored, delegate)
        self.assertEqual(
            _responds(
                stored, 'userNotificationCenter:shouldPresentNotification:'),
            1)
        presented = msg_send(
            ctypes.c_ubyte, stored,
            'userNotificationCenter:shouldPresentNotification:',
            center, notification)
        self.assertEqual(presented, 1)
        self.assertIsNotNone(delegate.center)
        self.assertIsNotNone(delegate.notification)

        center.setDelegate_(None)
        self.assertIsNone(center.delegate())

    def test_location_delegate_keeps_authorization_status_an_int(self):
        # macOS plyer calls setDelegate:. iOS plyer assigns the property.
        # Statuses 0, 2, and 4 must not collapse to bools: plyer compares
        # them with ==. Updates are not started.
        CLLocationManager = _require('CLLocationManager')
        # Fixed arguments, so the non-variadic objc_msgSend is the right
        # function on arm64 and x86-64.
        status_selector = OBJC.sel_registerName(
            b'locationManager:didChangeAuthorizationStatus:')
        send_status = ctypes.CFUNCTYPE(
            None, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p,
            ctypes.c_long)(('objc_msgSend', OBJC))
        selectors = (
            'locationManager:didChangeAuthorizationStatus:',
            'locationManager:didUpdateLocations:',
        )

        def install_by_property(manager, delegate):
            manager.delegate = delegate

        def install_by_setter(manager, delegate):
            manager.setDelegate_(delegate)

        for install in (install_by_property, install_by_setter):
            delegate = _LocationDelegate()
            manager = CLLocationManager.alloc().init()
            install(manager, delegate)
            # delegate is a property here, so reading it returns the proxy.
            stored = manager.delegate
            self.assertIsInstance(
                stored, ObjcClassInstance,
                'CLLocationManager.delegate is a property; reading it '
                'returns the proxy')
            _assert_same_proxy(self, stored, delegate)
            for name in selectors:
                self.assertEqual(_responds(stored, name), 1)
            for status in (0, 2, 4):
                send_status(
                    stored.get_address(), status_selector,
                    manager.get_address(), status)
                self.assertEqual(delegate.status, status)
                self.assertIsInstance(delegate.status, int)
