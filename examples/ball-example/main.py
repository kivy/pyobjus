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
