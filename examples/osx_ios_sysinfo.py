from kivy.app import App
from kivy.factory import Factory
from pyobjus import autoclass
from pyobjus.dylib_manager import load_framework, INCLUDE
from plyer.facades import UniqueID

load_framework(INCLUDE.Foundation)
UIDevice = autoclass('UIDevice')
NSProcessInfo = autoclass('NSProcessInfo')
processInfo = NSProcessInfo.processInfo()

class RavenApp(App):
    def build(self):
        return Factory.Button()
    def on_start(self):
        print "Hello Raven App"
        print 'ProcessName: ', processInfo.processName.cString()
        print 'HostName: ', processInfo.hostName.cString()
        print 'OS Version: ', processInfo.operatingSystemVersionString.cString()
        print 'ProcessorCount: ', processInfo.processorCount
        currentDevice = UIDevice.currentDevice()
        print 'DeviceName: ', currentDevice.name.cString()
        print 'SystemName: ', currentDevice.systemName.cString()
        print 'UI Idiom: ', currentDevice.userInterfaceIdiom
        print 'Orientation: ', currentDevice.orientation
        print 'SystemVersion: ', currentDevice.systemVersion.cString()
        print 'DeviceModel ', currentDevice.model.cString()
        print 'LocalizedModel: ', currentDevice.localizedModel.cString()
        print currentDevice.identifierForVendor.UUIDString().cString()
        print 'BatteryState:', currentDevice.batteryState


if __name__ == '__main__':
    RavenApp().run()

