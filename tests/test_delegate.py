import unittest
import ctypes
from pyobjus import autoclass, protocol, objc_str
from pyobjus.dylib_manager import load_dylib, load_framework, INCLUDE

NSURL = NSURLConnection = NSURLRequest = None


class _CFRunLoop(ctypes.Structure):
  pass

class _CFString(ctypes.Structure):
  pass


CF_RUN_LOOP_REF = ctypes.POINTER(_CFRunLoop)
CF_RUN_LOOP_RUN_RESULT = ctypes.c_int32
CF_STRING_REF = ctypes.POINTER(_CFString)
CF_TIME_INTERVAL = ctypes.c_double  # pylint: disable=invalid-name

cf = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))
cf.CFRunLoopGetCurrent.restype = CF_RUN_LOOP_REF
cf.CFRunLoopGetCurrent.argTypes = []
cf.CFRunLoopRunInMode.restype = CF_RUN_LOOP_RUN_RESULT
cf.CFRunLoopRunInMode.argtypes = [CF_STRING_REF, CF_TIME_INTERVAL,
                                  ctypes.c_bool]

K_CF_RUNLOOP_DEFAULT_MODE = CF_STRING_REF.in_dll(cf, 'kCFRunLoopDefaultMode')


class DelegateExample(object):
    def request_connection(self):
        self.delegate_called = False
        # This method request connection to an invalid URL so the
        # connection_didFailWithError_ protocol method will be triggered.
        url = NSURL.URLWithString_(objc_str('abc'))
        request = NSURLRequest.requestWithURL_(url)
        # Converts the Python delegate object to Objective C delegate instance
        # simply by calling the objc_delegate() function.
        connection = NSURLConnection.connectionWithRequest_delegate_(
                request, self)

    @protocol('NSURLConnectionDelegate')
    def connection_didFailWithError_(self, connection, error):
        self.delegate_called = True
        current = cf.CFRunLoopGetCurrent()
        cf.CFRunLoopStop(current)


class DeleguateTest(unittest.TestCase):
    def setUp(self):
        global NSURL, NSURLConnection, NSURLRequest
        load_framework(INCLUDE.AppKit)
        load_framework(INCLUDE.Foundation)
        NSURL = autoclass('NSURL')
        NSURLConnection = autoclass('NSURLConnection')
        NSURLRequest = autoclass('NSURLRequest')

    def test_delegate(self):
        instance = DelegateExample()
        instance.request_connection()
        cf.CFRunLoopRunInMode(K_CF_RUNLOOP_DEFAULT_MODE, 1, False)
        self.assertTrue(instance.delegate_called)
