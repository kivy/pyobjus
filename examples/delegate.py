"""
This example simplifies the code from the URL Loading System Programming Guide
(http://goo.gl/JJ2Q8T). It uses NSURLConnection to request an invalid connection
and get the connection:didFailWithError: delegate method triggered.
"""
from kivy.app import App
from kivy.uix.widget import Widget
from pyobjus import autoclass, objc_delegate, objc_str
from pyobjus.dylib_manager import load_framework, INCLUDE

load_framework(INCLUDE.AppKit)
load_framework(INCLUDE.Foundation)

NSURL = autoclass('NSURL')
NSURLConnection = autoclass('NSURLConnection')
NSURLRequest = autoclass('NSURLRequest')


class MyObjcDelegate:
  """A delegate class implemented in Python."""

  def connection_didFailWithError_(self, connection, error):
    print("Protocol method got called!!", connection, error)


def request_connection():
    # This method request connection to an invalid URL so the
    # connection_didFailWithError_ protocol method will be triggered.
    url = NSURL.URLWithString_(objc_str('abc'))
    request = NSURLRequest.requestWithURL_(url)
    # Converts the Python delegate object to Objective C delegate instance
    # simply by calling the objc_delegate() function.
    delegate = objc_delegate(MyObjcDelegate(), ['NSURLConnectionDelegate'])
    connection = NSURLConnection.connectionWithRequest_delegate_(request,
                                                                 delegate)


class DelegateApp(App):
  def build(self):
    request_connection()
    return Widget()

if __name__ == "__main__":
    DelegateApp().run()
