.. _pyobjus_ios:

Pyobjus on iOS
====================

You may wonder how to run pyobjus on iOS device. The solution for this problem is to use `kivy-ios <https://github.com/kivy/kivy-ios>`_.

As you can see, kivy-ios contains scripts for building kivy, pyobjus and other things nedded for they running, and also provide sciprts for making xcode project from which you can run your python kivy pyobjus applications. Sounds great, and it is.

Basic example
-------------

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
