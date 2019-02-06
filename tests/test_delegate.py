import unittest
import ctypes
import ctypes.util
from pyobjus import autoclass, protocol, objc_str, selector
from pyobjus.dylib_manager import load_dylib, load_framework, INCLUDE
from pyobjus.protocols import protocols

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
    # example of a delegate required by NSURLConnection
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


class IOSKeyboard(object):
    # example of Keyboard user-defined delegate (aka doesn't exists
    # in pyobjus) actually used for Kivy

    def __init__(self, **kwargs):
        super(IOSKeyboard, self).__init__()
        self.kheight = 0
        NSNotificationCenter = autoclass("NSNotificationCenter")
        center = NSNotificationCenter.defaultCenter()
        center.addObserver_selector_name_object_(
            self, selector("keyboardWillShow"),
            "UIKeyboardWillShowNotification",
            None)
        center.addObserver_selector_name_object_(
            self, selector("keyboardDidHide"),
            "UIKeyboardDidHideNotification",
            None)

    @protocol('KeyboardDelegates')
    def keyboardWillShow(self, notification):
        self.kheight = get_scale() * notification.userInfo().objectForKey_(
            'UIKeyboardFrameEndUserInfoKey').CGRectValue().size.height

    @protocol('KeyboardDelegates')
    def keyboardDidHide(self, notification):
        self.kheight = 0


class DelegateTest(unittest.TestCase):
    def setUp(self):
        global NSURL, NSURLConnection, NSURLRequest
        load_framework(INCLUDE.AppKit)
        load_framework(INCLUDE.Foundation)
        NSURL = autoclass('NSURL')
        NSURLConnection = autoclass('NSURLConnection')
        NSURLRequest = autoclass('NSURLRequest')

    def test_existing_delegate(self):
        instance = DelegateExample()
        instance.request_connection()
        cf.CFRunLoopRunInMode(K_CF_RUNLOOP_DEFAULT_MODE, 1, False)
        self.assertTrue(instance.delegate_called)

    def test_user_registration_delegate(self):
        protocols["KeyboardDelegates"] = {
            'keyboardWillShow': ('v16@0:4@8', "v32@0:8@16"),
            'keyboardDidHide': ('v16@0:4@8', "v32@0:8@16")}

        # if everything is find, the keyboard should instanciate
        # without issue
        iOSKeyboard = IOSKeyboard()

    def test_multiple_delegates(self):
      # Ensure we can create delegates for multiple instances of the same class
      # PR #50: https://github.com/kivy/pyobjus/pull/50
      conn1 = DelegateExample()
      conn2 = DelegateExample()
      conn1.request_connection()
      conn2.request_connection()
      cf.CFRunLoopRunInMode(K_CF_RUNLOOP_DEFAULT_MODE, 1, False)
      self.assertTrue(conn1.delegate_called)
      self.assertTrue(conn2.delegate_called)
