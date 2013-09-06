.. _pyobjus_ios:

Pyobjus on iOS
====================

You may wonder how to run pyobjus on iOS device. The solution for this problem is to use `kivy-ios <https://github.com/kivy/kivy-ios>`_.

As you can see, kivy-ios contains scripts for building kivy, pyobjus and other things nedded for them running, and also provide sciprts for making xcode project from which you can run your python kivy pyobjus applications. Sounds great, and it is.

Example with Kivy UI
--------------------

Let's first build kivy-ios. Execute following command::

    git clone https://github.com/kivy/kivy-ios.git
    cd kivy-ios
    tools/build-all.sh

This can take some time.

You can build you UI with kivy framework, and access to device hardware using pyobjus. So, let see one simple example of this. Note that tutorial how to use kivy-ios exists on kivy-ios official documentation, but here I will make another one, with focus on pyobjus.

Let we first make one simple example of using pyobjus with kivy.::

    from pyobjus import autoclass, objc_f, objc_str
    from kivy.app import App
    from kivy.uix.widget import Widget
    from kivy.uix.button import Button
    from kivy.uix.label import Label
    from kivy.graphics import Color, Ellipse, Line

    NSArray = autoclass('NSArray')
    array = NSArray.arrayWithObjects_(objc_f(0.3), objc_f(1), objc_f(1), None)

    class MyPaintWidget(Widget):

        def on_touch_down(self, touch):
            color = (array.objectAtIndex_(0).floatValue(), array.objectAtIndex_(1).floatValue(), array.objectAtIndex_(2).floatValue())
            with self.canvas:
                Color(*color, mode='hsv')
                d = 30.
                Ellipse(pos=(touch.x - d / 2, touch.y - d / 2), size=(d, d))
                touch.ud['line'] = Line(points=(touch.x, touch.y))

        def on_touch_move(self, touch):
            touch.ud['line'].points += [touch.x, touch.y]


    class MyPaintApp(App):

        def build(self):
            parent = Widget()
            painter = MyPaintWidget()
            btn_text = objc_str('Clear')
            clearbtn = Button(text=btn_text.UTF8String())
            parent.add_widget(painter)
            parent.add_widget(clearbtn)

            def clear_canvas(obj):
                painter.canvas.clear()
            clearbtn.bind(on_release=clear_canvas)

            return parent

    if __name__ == '__main__':
        MyPaintApp().run()

Please save this code inside file with name main.py. Make directory which will hold our python application code. For example you can do following::

    mkdir pyobjus-ios
    mv main.py pyobjus-ios

So now pyobjus-ios contains main.py file which holds python code.

Above app example is borrowed from `this <http://kivy.org/docs/tutorials/firstwidget.html>`_ tutorial, and I added some pyobjus things to it. So we are now using NSArray to store information about line color, and we are using NSString to set text of button.

Now you can create xcode project, which will hold our python application. kivy-ios commes with script for creating xcode projects for you. You only need to specify project name and absolute path path to your app.

Execute following command::

    tools/create-xcode-project.sh paintApp /Users/myName/development/kivy-ios/pyobjus-ios/

Note following. First parameter which we are passing to script is name of our app. In this case that name of iOS app will be paintApp. Second parameter is absolute path to our python app which we want to run on iOS.
You need to specify absolute path to your pyobjus-ios directory, because above we put main.py script in it.

After executing this command you will get outpout simmimlar to this::

    -> Create /Users/myName/development/kivy-ios/app-paintapp directory
    -> Copy templates
    -> Customize templates
    -> Done !

    Your project is available at /Users/myName/development/kivy-ios/app-paintapp

    You can now type: open /Users/myName/development/kivy-ios/app-paintapp/paintapp.xcodeproj

So, if you enter into app-paintapp directory you will see that there are main.m and bridge.h/bridge.m and other resources.

You can open this project with xcode now::

    open /Users/myName/development/kivy-ios/app-paintapp/paintapp.xcodeproj

So if you have set your developer account, you only need to click play, and app will be deployed on your iOS device.

This is screenshoot from my iPad

.. figure::  images/IMG_0322.PNG
   :align:   center
   :scale:   30%

Accessing accelerometer
-----------------------

As you knows, to access accelerometer on iOS device you use CoreMotion framework. CoreMotion framework is added to default project template which ships with kivy-ios.

Let we say that we have class interface with following properties and variable::

    @interface bridge : NSObject {
        NSOperationQueue *queue;
    }

    @property (strong, nonatomic) CMMotionManager *motionManager;
    @property (nonatomic) double ac_x;
    @property (nonatomic) double ac_y;
    @property (nonatomic) double ac_z;
    @end

Also let we say that we have init method which inits motionManager and queue, and we have method for running accelerometer, and method is declared as follows::

    - (void)startAccelerometer {
        if ([self.motionManager isAccelerometerAvailable] == YES) {
            [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                self.ac_x = accelerometerData.acceleration.x;
                self.ac_y = accelerometerData.acceleration.y;
                self.ac_z = accelerometerData.acceleration.z;
            }];
        }
    }

You see here that we are specifying handler which will be called when we get some updates from accelerometer. Currently you can't implement this handler from pyobjus, so that may be a problem.

But, we have also solution for this. We added bridge class, with this purpose, to implement handlers inside pure Objective C, and then we call methods of bridge class so we can get actual data.
In this example we are storing x, y and z from accelerometer to ac_x, ac_y and ac_z class properties, and as you know, we can easily access to class properties.

So let we see basic example how to read accelerometer data from pyobjus::

    from pyobjus import autoclass

    def run():
        Bridge = autoclass('bridge')
        br = Bridge.alloc().init()
        br.motionManager.setAccelerometerUpdateInterval_(0.1)
        br.startAccelerometer()

        for i in range(10000):
            print 'x: {0} y: {1} z: {2}'.format(br.ac_x, br.ac_y, br.ac_z)

        br.stopAccelerometer()

    if __name__ == "__main__":
        run()

So if you run this script on ipad, in the way we showed above, you'll outpout simmilar to this in xcode console::

    x: 0.0219268798828 y: 0.111801147461 z: -0.976440429688
    x: 0.0219268798828 y: 0.111801147461 z: -0.976440429688
    x: 0.0219268798828 y: 0.111801147461 z: -0.976440429688
    x: 0.0219268798828 y: 0.111801147461 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945

As you can see, we have data from accelerometer, so we can use it for some practical purposes if we want.

Accessing gyroscope
-------------------

In simmilar way as the accessing accelerometer you can access gyroscope. So let's expand our bridge class interface with properties which will hold gyro data::

    @property (nonatomic) double gy_x;
    @property (nonatomic) double gy_y;
    @property (nonatomic) double gy_z;

Then in bridge class implementation add following method::

    - (void)startGyroscope {
        
        if ([self.motionManager isGyroAvailable] == YES) {
            [self.motionManager startGyroUpdatesToQueue:queue withHandler:^(CMGyroData *gyroData, NSError *error) {
                self.gy_x = gyroData.rotationRate.x;
                self.gy_y = gyroData.rotationRate.y;
                self.gy_z = gyroData.rotationRate.z;
            }];
        }
    }

I suppose that this method is known, because is very simmilar as the method for getting accelerometer data. Let's write some python code to read data from python::

    from pyobjus import autoclass

    def run():
        Bridge = autoclass('bridge')
        br = Bridge.alloc().init()
        br.startGyroscope()

        for i in range(10000):
            print 'x: {0} y: {1} z: {2}'.format(br.gy_x, br.gy_y, br.gy_z)

        br.stopGyroscope()

    if __name__ == "__main__":
        run()

You will output simmilar to this::

    x: 0.019542276079 y: 0.0267431973505 z: 0.00300590992237
    x: 0.019542276079 y: 0.0267431973505 z: 0.00300590992237
    x: 0.019542276079 y: 0.0267431973505 z: 0.00300590992237
    x: 0.019542276079 y: 0.0267431973505 z: 0.00300590992237
    x: 0.019542276079 y: 0.0267431973505 z: 0.00300590992237
    x: 0.019542276079 y: 0.018291389315 z: -0.00338913880323
    x: 0.018301243011 y: 0.018291389315 z: -0.00338913880323
    x: 0.018301243011 y: 0.018291389315 z: -0.00338913880323
    x: 0.018301243011 y: 0.018291389315 z: -0.00338913880323
    x: 0.018301243011 y: 0.018291389315 z: -0.00338913880323
    x: 0.018301243011 y: 0.018291389315 z: -0.00338913880323
    x: 0.0183009766949 y: 0.0170807162834 z: -0.00339499775763
    x: 0.0183009766949 y: 0.0170807162834 z: -0.00339499775763

So now you can use gyro data in you python kivy application.

Accessing magnetometer
----------------------

TODO:
