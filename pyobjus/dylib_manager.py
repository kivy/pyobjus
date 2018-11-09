import os
import ctypes
from pyobjus import dprint, autoclass, ObjcException
from .objc_py_types import enum

try:
    from subprocess import call
except:
    call = None


def load_dylib(path, **kwargs):
    ''' Function for loading dynamic library with ctypes

    Args:
        path: Path to user defined library
        abs_path: If setted to True, pyobjus will load library with absolute path provided by user -> path arg
        Otherwise it will look in /objc_usr_classes dir, which is in pyobjus root dir

    Note:
        Work in progress
    '''

    # LOADING USER DEFINED CLASS (dylib) FROM /objc_classes/test/ DIR #
    usr_path = kwargs.get('usr_path', True)
    if not usr_path:
        root_pyobjus = os.path.join(os.path.dirname(__file__), "..")
        objc_test_dir = os.path.join(root_pyobjus, 'objc_classes', 'test')
        ctypes.CDLL(os.path.join(objc_test_dir, path))
    else:
        ctypes.CDLL(path)
    dprint("Dynamic library {0} loaded".format(path))

def make_dylib(path, **kwargs):
    ''' Function for making .dylib from some .m file

    Args:
        path: Path to some .m file which we want to convert to .dylib

    Note:
        Work in progress
    '''
    frameworks = kwargs.get('frameworks', None)
    out = kwargs.get('out', None)
    additional_opts = kwargs.get('options', None)

    if not out:
        out = '.'.join([os.path.splitext(path)[0], 'dylib'])
    arg_list = ["clang", path, "-o", out, "-dynamiclib"]
    if additional_opts is not None:
        arg_list = arg_list + additional_opts
    if frameworks:
        for framework in frameworks:
            arg_list.append('-framework')
            arg_list.append(framework)
    call(arg_list)

frameworks = dict(
    Accelerate = '/System/Library/Frameworks/Accelerate.framework',
    Accounts = '/System/Library/Frameworks/Accounts.framework',
    AddressBook = '/System/Library/Frameworks/AddressBook.framework',
    AGL = '/System/Library/Frameworks/AGL.framework',
    AppKit = '/System/Library/Frameworks/AppKit.framework',
    AppKitScripting = '/System/Library/Frameworks/AppKitScripting.framework',
    AppleScriptKit = '/System/Library/Frameworks/AppleScriptKit.framework',
    AppleScriptObjC = '/System/Library/Frameworks/AppleScriptObjC.framework',
    AppleShareClientCore = '/System/Library/Frameworks/AppleShareClientCore.framework',
    AppleTalk = '/System/Library/Frameworks/AppleTalk.framework',
    ApplicationServices = '/System/Library/Frameworks/ApplicationServices.framework',
    AudioToolbox = '/System/Library/Frameworks/AudioToolbox.framework',
    AudioUnit = '/System/Library/Frameworks/AudioUnit.framework',
    AudioVideoBridging = '/System/Library/Frameworks/AudioVideoBridging.framework',
    Automator = '/System/Library/Frameworks/Automator.framework',
    AVFoundation = '/System/Library/Frameworks/AVFoundation.framework',
    CalendarStore = '/System/Library/Frameworks/CalendarStore.framework',
    Carbon = '/System/Library/Frameworks/Carbon.framework',
    CFNetwork = '/System/Library/Frameworks/CFNetwork.framework',
    Cocoa = '/System/Library/Frameworks/Cocoa.framework',
    Collaboration = '/System/Library/Frameworks/Collaboration.framework',
    CoreAudio = '/System/Library/Frameworks/CoreAudio.framework',
    CoreAudioKit = '/System/Library/Frameworks/CoreAudioKit.framework',
    CoreData = '/System/Library/Frameworks/CoreData.framework',
    CoreFoundation = '/System/Library/Frameworks/CoreFoundation.framework',
    CoreGraphics = '/System/Library/Frameworks/CoreGraphics.framework',
    CoreLocation = '/System/Library/Frameworks/CoreLocation.framework',
    CoreMedia = '/System/Library/Frameworks/CoreMedia.framework',
    CoreMediaIO = '/System/Library/Frameworks/CoreMediaIO.framework',
    CoreMIDI = '/System/Library/Frameworks/CoreMIDI.framework',
    CoreMIDIServer = '/System/Library/Frameworks/CoreMIDIServer.framework',
    CoreServices = '/System/Library/Frameworks/CoreServices.framework',
    CoreText = '/System/Library/Frameworks/CoreText.framework',
    CoreVideo = '/System/Library/Frameworks/CoreVideo.framework',
    CoreWiFi = '/System/Library/Frameworks/CoreWiFi.framework',
    CoreWLAN = '/System/Library/Frameworks/CoreWLAN.framework',
    DirectoryService = '/System/Library/Frameworks/DirectoryService.framework',
    DiscRecording = '/System/Library/Frameworks/DiscRecording.framework',
    DiscRecordingUI = '/System/Library/Frameworks/DiscRecordingUI.framework',
    DiskArbitration = '/System/Library/Frameworks/DiskArbitration.framework',
    DrawSprocket = '/System/Library/Frameworks/DrawSprocket.framework',
    DVComponentGlue = '/System/Library/Frameworks/DVComponentGlue.framework',
    DVDPlayback = '/System/Library/Frameworks/DVDPlayback.framework',
    EventKit = '/System/Library/Frameworks/EventKit.framework',
    ExceptionHandling = '/System/Library/Frameworks/ExceptionHandling.framework',
    ForceFeedback = '/System/Library/Frameworks/ForceFeedback.framework',
    Foundation = '/System/Library/Frameworks/Foundation.framework',
    FWAUserLib = '/System/Library/Frameworks/FWAUserLib.framework',
    GameKit = '/System/Library/Frameworks/GameKit.framework',
    GLKit = '/System/Library/Frameworks/GLKit.framework',
    GLUT = '/System/Library/Frameworks/GLUT.framework',
    GSS = '/System/Library/Frameworks/GSS.framework',
    ICADevices = '/System/Library/Frameworks/ICADevices.framework',
    ImageCaptureCore = '/System/Library/Frameworks/ImageCaptureCore.framework',
    ImageIO = '/System/Library/Frameworks/ImageIO.framework',
    IMServicePlugIn = '/System/Library/Frameworks/IMServicePlugIn.framework',
    InputMethodKit = '/System/Library/Frameworks/InputMethodKit.framework',
    InstallerPlugins = '/System/Library/Frameworks/InstallerPlugins.framework',
    InstantMessage = '/System/Library/Frameworks/InstantMessage.framework',
    IOBluetooth = '/System/Library/Frameworks/IOBluetooth.framework',
    IOBluetoothUI = '/System/Library/Frameworks/IOBluetoothUI.framework',
    IOKit = '/System/Library/Frameworks/IOKit.framework',
    IOSurface = '/System/Library/Frameworks/IOSurface.framework',
    JavaFrameEmbedding = '/System/Library/Frameworks/JavaFrameEmbedding.framework',
    JavaScriptCore = '/System/Library/Frameworks/JavaScriptCore.framework',
    JavaVM = '/System/Library/Frameworks/JavaVM.framework',
    Kerberos = '/System/Library/Frameworks/Kerberos.framework',
    Kernel = '/System/Library/Frameworks/Kernel.framework',
    LatentSemanticMapping = '/System/Library/Frameworks/LatentSemanticMapping.framework',
    LDAP = '/System/Library/Frameworks/LDAP.framework',
    MediaToolbox = '/System/Library/Frameworks/MediaToolbox.framework',
    Message = '/System/Library/Frameworks/Message.framework',
    NetFS = '/System/Library/Frameworks/NetFS.framework',
    OpenAL = '/System/Library/Frameworks/OpenAL.framework',
    OpenCL = '/System/Library/Frameworks/OpenCL.framework',
    OpenDirectory = '/System/Library/Frameworks/OpenDirectory.framework',
    OpenGL = '/System/Library/Frameworks/OpenGL.framework',
    OSAKit = '/System/Library/Frameworks/OSAKit.framework',
    PCSC = '/System/Library/Frameworks/PCSC.framework',
    PreferencePanes = '/System/Library/Frameworks/PreferencePanes.framework',
    PubSub = '/System/Library/Frameworks/PubSub.framework',
    Python = '/System/Library/Frameworks/Python.framework',
    QTKit = '/System/Library/Frameworks/QTKit.framework',
    Quartz = '/System/Library/Frameworks/Quartz.framework',
    QuartzCore = '/System/Library/Frameworks/QuartzCore.framework',
    QuickLook = '/System/Library/Frameworks/QuickLook.framework',
    QuickTime = '/System/Library/Frameworks/QuickTime.framework',
    Ruby = '/System/Library/Frameworks/Ruby.framework',
    RubyCocoa = '/System/Library/Frameworks/RubyCocoa.framework',
    SceneKit = '/System/Library/Frameworks/SceneKit.framework',
    ScreenSaver = '/System/Library/Frameworks/ScreenSaver.framework',
    Scripting = '/System/Library/Frameworks/Scripting.framework',
    ScriptingBridge = '/System/Library/Frameworks/ScriptingBridge.framework',
    Security = '/System/Library/Frameworks/Security.framework',
    SecurityFoundation = '/System/Library/Frameworks/SecurityFoundation.framework',
    SecurityInterface = '/System/Library/Frameworks/SecurityInterface.framework',
    ServerNotification = '/System/Library/Frameworks/ServerNotification.framework',
    ServiceManagement = '/System/Library/Frameworks/ServiceManagement.framework',
    Social = '/System/Library/Frameworks/Social.framework',
    StoreKit = '/System/Library/Frameworks/StoreKit.framework',
    SyncServices = '/System/Library/Frameworks/SyncServices.framework',
    System = '/System/Library/Frameworks/System.framework',
    SystemConfiguration = '/System/Library/Frameworks/SystemConfiguration.framework',
    Tcl = '/System/Library/Frameworks/Tcl.framework',
    Tk = '/System/Library/Frameworks/Tk.framework',
    TWAIN = '/System/Library/Frameworks/TWAIN.framework',
    vecLib = '/System/Library/Frameworks/vecLib.framework',
    VideoDecodeAcceleration = '/System/Library/Frameworks/VideoDecodeAcceleration.framework',
    VideoToolbox = '/System/Library/Frameworks/VideoToolbox.framework',
    WebKit = '/System/Library/Frameworks/WebKit.framework',
    XgridFoundation = '/System/Library/Frameworks/XgridFoundation.framework'
)

INCLUDE = enum('pyobjus_include', **frameworks)

def load_framework(framework):
    ''' Function for loading frameworks

    Args:
        framework: Framework to load

    Raises:
        ObjcException if it can't load framework
    '''
    NSBundle = autoclass('NSBundle')
    ns_framework = autoclass('NSString').stringWithUTF8String_(framework)
    bundle = NSBundle.bundleWithPath_(ns_framework)
    try:
        if bundle.load():
            dprint("Framework {0} succesufully loaded!".format(framework))
    except:
        raise ObjcException('Error while loading {0} framework'.format(framework))
