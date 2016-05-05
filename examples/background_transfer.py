# -*- coding: utf-8 -*-
"""
This class provides a Background Transfer Service for iOS. It requires iOS 8 or
later.

Note that downloading from non-https sources requires modifying the Info.plist
file.

http://stackoverflow.com/questions/32631184/the-resource-could-not-be-loaded-because-the-app-transport-security-policy-requi

Note that on iOS 9 and above, the 'NSExceptionAllowsInsecureHTTPLoads' key
also seems to be required and set to true to allow HTTP downloads.
"""
from pyobjus import autoclass, protocol, objc_str, selector, objc_b
from pyobjus.dylib_manager import make_dylib, load_dylib
from pyobjus.dylib_manager import load_framework, INCLUDE
from kivy.app import App
from kivy.uix.label import Label
from kivy.logger import Logger
from kivy.properties import ObjectProperty
from kivy.logger import Logger


class TestApp(App):
    """ Our test app for background downloading """
    bg_transfer = ObjectProperty()

    def build(self):
        return Label(text="Background Transfer Demo.\nFor iOS 8 or later.")


class BackgroundTransfer(object):
    """
    Main worker class for handling background transfers
    """
    identifier = objc_str('Kivy Background Transfer')

    def __init__(self):
        super(BackgroundTransfer, self).__init__()
        load_framework(INCLUDE.Foundation)

        # Load the configuration required for background sessions
        ns_config = autoclass('NSURLSessionConfiguration')
        self.config = ns_config.backgroundSessionConfigurationWithIdentifier_(
            self.identifier)

        # Load the session using the config and this class as the delegate
        session = autoclass('NSURLSession')
        self.session = session.sessionWithConfiguration_delegate_delegateQueue_(
            self.config, self, None)

        self.task = None
        # Note the policy restriction on HTTP as mentioned in the doc string
        # Use HTTPS to make you life easier :-) 
        self.download_file('http://kivy.org/logos/kivy-logo-black-256.png')

    def download_file(self, url):
        """ Download the specified file in place it in the destination. """
        NSURL = autoclass('NSURL')
        oc_url = NSURL.URLWithString_(objc_str(url))

        # Tasks are intialised in a paused state
        self.task = self.session.downloadTaskWithURL_(oc_url)
        self.task.resume()

    def close_session(self):
        """ Close the session. This is required to prevent memory leaks after
        all the downloads have completed.

        https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/#//apple_ref/occ/instm/NSURLSession/downloadTaskWithURL:
        """
        self.session.finishTasksAndInvalidate()

    @protocol('NSURLSessionDownloadDelegate')
    def URLSession_downloadTask_didWriteData_totalBytesWritten_totalBytesExpectedToWrite_(self, *args):
        Logger.info(
            "background_transfer.py: Protocol method "
            "URLSession_downloadTask_didWriteData_totalBytesWritten_"
            "totalBytesExpectedToWrite_ with {0}".format(args))

    @protocol('NSURLSessionDownloadDelegate')
    def URLSession_downloadTask_didFinishDownloadingToURL_(self, *args):
        Logger.info(
            "background_transfer.py: Protocol method "
            "URLSession_downloadTask_didFinishDownloadingToURL_ "
            "with {0}".format(args))
        if len(args) > 2:
            ns_url = args[2]
            Logger.info(
                'Downloaded file is {0}.\nYou need to move this before the '
                'function returns.'.format(ns_url.fileSystemRepresentation))
        self.close_session()

    @protocol('NSURLSessionDownloadDelegate')
    def URLSession_downloadTask_didResumeAtOffset_expectedTotalBytes_(self,
                                                                      *args):
        Logger.info(
            "background_transfer.py: Protocol method "
            "URLSession_downloadTask_didResumeAtOffset_expectedTotalBytes_"
            " with {0}".format(args))

    @protocol('NSURLSessionTaskDelegate')
    def URLSession_task_didCompleteWithError_(self, *args):
        """
        Although not technically part of the required delegate class, this
        delegate catches errors preventing the main delegate from functioning.
        """
        Logger.info(
            "background_transfer.py: Protocol method "
            "URLSession_task_didCompleteWithError_"
            "with {0}".format(args))

        if len(args) > 2:
            ns_err = args[2]
            if ns_err is not None:
                Logger.info('background_transfer: Error {}'.format(
                     ns_err.description().cString()))

if __name__ == '__main__':
    TestApp(bg_transfer=BackgroundTransfer()).run()

