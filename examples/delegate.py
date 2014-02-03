"""
This example simplifies the code from the URL Loading System Programming Guide
(http://goo.gl/JJ2Q8T). It uses NSURLConnection to request an invalid connection
and get the connection:didFailWithError: delegate method triggered.
"""
from kivy.app import App
from kivy.uix.widget import Widget
from pyobjus import autoclass, protocol, objc_str
from pyobjus.dylib_manager import load_framework, INCLUDE

load_framework(INCLUDE.AppKit)
load_framework(INCLUDE.Foundation)

NSURL = autoclass('NSURL')
NSURLConnection = autoclass('NSURLConnection')
NSURLRequest = autoclass('NSURLRequest')

class DelegateApp(App):

    def build(self):
        self.request_connection()
        return Widget()

    def request_connection(self):
        # This method request connection to an invalid URL so the
        # connection_didFailWithError_ protocol method will be triggered.
        url = NSURL.URLWithString_(objc_str('abc'))
        request = NSURLRequest.requestWithURL_(url)
        # Converts the Python delegate object to Objective C delegate instance
        # simply by calling the objc_delegate() function.
        connection = NSURLConnection.connectionWithRequest_delegate_(
                request, self)

        return connection

    @protocol('NSURLConnectionDelegate')
    def connection_didFailWithError_(self, connection, error):
        print("Protocol method got called!!", connection, error)


if __name__ == "__main__":
    DelegateApp().run()
