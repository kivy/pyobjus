.. _pyobjus_ios:

Pyobjus on iOS
==============

You may be wondering how to run pyobjus on iOS devices?
The solution for this problem is to use `kivy-ios <https://github.com/kivy/kivy-ios>`_.

As you can see, kivy-ios contains scripts for building kivy, pyobjus and other things
needed for running. It also provide scripts for making xcode projects from which you
can run your python kivy pyobjus applications. Sounds great, and it is.

Example with Kivy UI
--------------------

Let's first build kivy-ios. Execute following command::

    git clone https://github.com/kivy/kivy-ios.git
    cd kivy-ios
    tools/build-all.sh

This can take some time.

You can build your UI with the kivy framework, and access device hardware
using pyobjus. So, let's look at one simple example of this. Notice that
a tutorial describing how to use kivy-ios exists as part of the official
kivy-ios documentation, but here we will provide another one, with focus on
pyobjus.

Let's first make one simple example of using pyobjus with kivy.::

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

Please save this code inside a file with the name ``main.py``. You will need to
make a directory which will hold your python application code. For example, you
can do the following::

    mkdir pyobjus-ios
    mv main.py pyobjus-ios

So now ``pyobjus-ios`` contains ``main.py`` file which holds python code.

The example above is borrowed from `this <http://kivy.org/docs/tutorials/firstwidget.html>`_
tutorial but we have added some pyobjus things to it. So we are now using a
``NSArray`` to store information about line color, and we are using a
``NSString`` to set the text of the button.

Now you can create an xcode project which will hold our python application.
kivy-ios comes with script for creating xcode projects for you. You only need
to specify project name and the absolute path to your app.

Execute the following command::

    tools/create-xcode-project.sh paintApp /Users/myName/development/kivy-ios/pyobjus-ios/

Notice the following. First parameter which we are passing to the script is the
name of our app. In this case, the name of our iOS app will be `paintApp`.
The second parameter is the absolute path to our python app which we want to
run on iOS.

After executing this command you will get output similar to this::

    -> Create /Users/myName/development/kivy-ios/app-paintapp directory
    -> Copy templates
    -> Customize templates
    -> Done !

    Your project is available at /Users/myName/development/kivy-ios/app-paintapp

    You can now type: open /Users/myName/development/kivy-ios/app-paintapp/paintapp.xcodeproj

So, if you enter the `app-paintapp` directory you will see that there are
``main.m``, ``bridge.m`` and other resources.

You can open this project with xcode now::

    open /Users/myName/development/kivy-ios/app-paintapp/paintapp.xcodeproj

If you have setup your developer account, you only need to click play and the
app will be deployed on your iOS device.

This is screenshoot from my iPad.

.. figure::  images/IMG_0322.PNG
   :align:   center
   :scale:   30%

Accessing accelerometer
-----------------------

As you know, to access accelerometer on iOS device, you use CoreMotion framework. CoreMotion framework is added to default project template which ships with kivy-ios.

Let's say that we have class interface with following properties and variable::

    @interface bridge : NSObject {
        NSOperationQueue *queue;
    }

    @property (strong, nonatomic) CMMotionManager *motionManager;
    @property (nonatomic) double ac_x;
    @property (nonatomic) double ac_y;
    @property (nonatomic) double ac_z;
    @end

Also let's say that we have init method which inits ``motionManager`` and ``queue``, and we have method for running accelerometer, and method is declared as following::

    - (void)startAccelerometer {
        if ([self.motionManager isAccelerometerAvailable] == YES) {
            [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                self.ac_x = accelerometerData.acceleration.x;
                self.ac_y = accelerometerData.acceleration.y;
                self.ac_z = accelerometerData.acceleration.z;
            }];
        }
    }

You can see here that we are specifying handler which will be called when we get some updates from accelerometer. Currently you can't implement this handler from pyobjus, so that may be a problem.

But, we have also solution for this. We have added bridge class, with this purpose, to implement handlers inside pure Objective C, and then we call methods of bridge class so we can get actual data.
In this example we are storing `x`, `y` and `z` from accelerometer to ``ac_x``, ``ac_y`` and ``ac_z`` class properties, and as you know, we can easily access to class properties.

So let's see basic example how to read accelerometer data from pyobjus::

    from pyobjus import autoclass

    def run():
        Bridge = autoclass('bridge')
        br = Bridge.alloc().init()
        br.motionManager.setAccelerometerUpdateInterval_(0.1)
        br.startAccelerometer()

        for i in range(10000):
            print 'x: {0} y: {1} z: {2}'.format(br.ac_x, br.ac_y, br.ac_z)

    if __name__ == "__main__":
        run()

So if you run this script on ipad, in the way we have showed above, you'll outpout simmilar to this in xcode console::

    x: 0.0219268798828 y: 0.111801147461 z: -0.976440429688
    x: 0.0219268798828 y: 0.111801147461 z: -0.976440429688
    x: 0.0219268798828 y: 0.111801147461 z: -0.976440429688
    x: 0.0219268798828 y: 0.111801147461 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945
    x: 0.145629882812 y: -0.00624084472656 z: -0.964920043945

As you can see, we have data from accelerometer, so you can use it for some practical purposes if you want.

Accessing gyroscope
-------------------

In a similar way, as the accessing accelerometer, you can access gyroscope. So let's expand our bridge class interface with properties which will hold gyro data::

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

I suppose that this method is known to you, because is very similar as the method for getting accelerometer data. Let's write some python code to read data from python::

    from pyobjus import autoclass

    def run():
        Bridge = autoclass('bridge')
        br = Bridge.alloc().init()
        br.startGyroscope()

        for i in range(10000):
            print 'x: {0} y: {1} z: {2}'.format(br.gy_x, br.gy_y, br.gy_z)

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

I suppose that you can guess that this will be almost identical as those two previous. Let's add two new properties to interface of bridge class::

    @property (nonatomic) double mg_x;
    @property (nonatomic) double mg_y;
    @property (nonatomic) double mg_z;

And add following method to bridge class::

    - (void)startMagnetometer {        
        if (self.motionManager.magnetometerAvailable) {
            [self.motionManager startMagnetometerUpdatesToQueue:queue withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
                self.mg_x = magnetometerData.magneticField.x;
                self.mg_y = magnetometerData.magneticField.y;
                self.mg_z = magnetometerData.magneticField.z;
            }];
        }
    }

Now we can use the methods above from pyobjus to get data from magnetometer::

    from pyobjus import autoclass

    def run():
        Bridge = autoclass('bridge')
        br = Bridge.alloc().init()
        br.startMagnetometer()

        for i in range(10000):
            print 'x: {0} y: {1} z: {2}'.format(br.mg_x, br.mg_y, br.mg_z)

    if __name__ == "__main__":
        run()


You will get outpout similar to this::

    x: 29.109375 y: -46.694519043 z: -27.4476470947
    x: 29.109375 y: -46.694519043 z: -27.4476470947
    x: 29.109375 y: -47.7679595947 z: -24.6468658447
    x: 28.03125 y: -47.7679595947 z: -24.6468658447
    x: 28.03125 y: -47.7679595947 z: -24.6468658447
    : 28.03125 y: -47.7679595947 z: -24.6468658447
    x: 28.03125 y: -47.7679595947 z: -24.6468658447
    x: 28.03125 y: -48.3046875 z: -27.4476470947
    x: 27.4921875 y: -48.3046875 z: -27.4476470947
    x: 27.4921875 y: -48.3046875 z: -27.4476470947
    x: 27.4921875 y: -48.3046875 z: -27.4476470947
    x: 27.4921875 y: -48.3046875 z: -27.4476470947
    x: 27.4921875 y: -47.2312469482 z: -28.5679626

You can add additional bridge methods to your pyobjus iOS app, just change content of `bridge.m/.h` files, or add completely new files and classes to your xcode project, and after that you can consume them with pyobjus, on the already known way.

Pyobjus-ball example
--------------------

We made simple example of using accelerometer to control ball on screen. Also, with this example you can set you screen brightness using kivy slider.

I won't explain details about kivy language or kivy itself, you can find excellent examples and docs on official kivy site.

So, here is the code of ``main.py`` file::

    from random import random
    from kivy.app import App
    from kivy.uix.widget import Widget
    from kivy.properties import NumericProperty, ReferenceListProperty, ObjectProperty
    from kivy.vector import Vector
    from kivy.clock import Clock
    from kivy.graphics import Color
    from pyobjus import autoclass

    class Ball(Widget):

        velocity_x = NumericProperty(0)
        velocity_y = NumericProperty(0)
        h = NumericProperty(0)
        velocity = ReferenceListProperty(velocity_x, velocity_y)

        def move(self):
            self.pos = Vector(*self.velocity) + self.pos

    class PyobjusGame(Widget):

        ball = ObjectProperty(None)
        screen = ObjectProperty(autoclass('UIScreen').mainScreen())
        bridge = ObjectProperty(autoclass('bridge').alloc().init())
        sensitivity = ObjectProperty(50)
        br_slider = ObjectProperty(None)

        def __init__(self, *args, **kwargs):
            super(PyobjusGame, self).__init__()
            self.bridge.startAccelerometer()

        def __dealloc__(self, *args, **kwargs):
            self.bridge.stopAccelerometer()
            super(PyobjusGame, self).__dealloc__()

        def reset_ball_pos(self):
            self.ball.pos = self.width / 2, self.height / 2

        def on_bright_slider_change(self):
            self.screen.brightness = self.br_slider.value

        def update(self, dt):
            self.ball.move()
            self.ball.velocity_x = self.bridge.ac_x * self.sensitivity
            self.ball.velocity_y = self.bridge.ac_y * self.sensitivity

            if (self.ball.y < 0) or (self.ball.top >= self.height):
                self.reset_ball_pos()
                self.ball.h = random()

            if (self.ball.x < 0) or (self.ball.right >= self.width):
                self.reset_ball_pos()
                self.ball.h = random()


    class PyobjusBallApp(App):

        def build(self):
            game = PyobjusGame()
            Clock.schedule_interval(game.update, 1.0/60.0)
            return game


    if __name__ == '__main__':
        PyobjusBallApp().run()

And contents of ``pyobjusball.kv`` is::

    <Ball>:
        size: 50, 50
        h: 0
        canvas:
            Color:
                hsv: self.h, 1, 1,
            Ellipse:
                pos: self.pos
                size: self.size          

    <PyobjusGame>:
        ball: pyobjus_ball
        br_slider: bright_slider

        Label:
            text: 'Screen brightness'
            pos: bright_slider.x, bright_slider.y + bright_slider.height / 2
        Slider:
            pos: self.parent.width / 4, self.parent.height / 1.1
            id: bright_slider
            value: 0.5
            max: 1
            min: 0
            width: self.parent.width / 2
            height: self.parent.height / 10
            on_touch_up: root.on_bright_slider_change()

        Ball:
            id: pyobjus_ball
            center: self.parent.center

Now create directory with name ``pyobjus-ball`` and place the files above in it::

    mkdir pyobjus-ball
    mv main.py pyobjus-ball
    mv pyobjusball.kv pyobjus-ball

In this step, I suppose that you already have downloaded and built ``kivy-ios`` so, please navigate to directory where ``kivy-ios`` is located.
Now execute following::

    tools/create-xcode-project.sh pyobjusBall /path/to/pyobjus-ball
    open app-pyobjusball/pyobjusball.xcodeproj/

After this step xcode will be opened, and if you have connected your iOS device on you computer, you can run project, and you will see app running on your device.

This is screenshoot from iPad.

.. figure::  images/IMG_0330.PNG
   :align:   center
   :scale:   30%