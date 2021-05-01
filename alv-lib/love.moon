import Constant, Op, PureOp, Input, T, Struct, sig, evt from require 'alv.base'

unpack or= table.unpack

class DrawId
  new: =>

draw = Constant.meta
  meta:
    name: 'draw'
    summary: "draw a love/shape shape."
    examples: { '(love/draw shape)' }

  value: class extends Op
    new: (...) =>
      super ...
      @state or= DrawId!

    pattern = sig['love/shape']*0
    setup: (inputs, scope) =>
      shapes = pattern\match inputs
      super [Input.hot shape for shape in *shapes]

    tick: =>
      shapes = @unwrap_all!
      COPILOT.drawlist[@state] = shapes

    destroy: =>
      COPILOT.drawlist[@state] = nil

rectangle = Constant.meta
  meta:
    name: 'rectangle'
    summary: "create a rectangle shape."
    examples: { '(love/rectangle mode w h)' }

  value: class extends PureOp
    pattern: sig.str + sig.num + sig.num
    type: T['love/shape']

    tick: =>
      { mode, w, h } = @unwrap_all!
      x, y = -w/2, -h/2

      @out\set ->
        love.graphics.rectangle mode, x, y, w, h

color = Constant.meta
  meta:
    name: 'color'
    summary: "set color of a shape."
    examples: { '(love/color r g b [a] shape)' }

  value: class extends PureOp
    pattern: sig.num\rep(3, 4) + sig['love/shape']
    type: T['love/shape']

    tick: =>
      { color, shape } = @unwrap_all!
      { r, g, b, a } = color

      @out\set ->
        love.graphics.setColor r, g, b, a
        shape!
        love.graphics.setColor 255, 255, 255

translate = Constant.meta
  meta:
    name: 'translate'
    summary: "translate a shape."
    examples: { '(love/translate x y hape)' }

  value: class extends PureOp
    pattern: sig.num + sig.num + sig['love/shape']
    type: T['love/shape']

    tick: =>
      { x, y, shape } = @unwrap_all!

      @out\set ->
        love.graphics.push!
        love.graphics.translate x, y
        shape!
        love.graphics.pop!

rotate = Constant.meta
  meta:
    name: 'rotate'
    summary: "rotate a shape."
    examples: { '(love/rotate angle hape)' }

  value: class extends PureOp
    pattern: sig.num + sig['love/shape']
    type: T['love/shape']

    tick: =>
      { angle, shape } = @unwrap_all!

      @out\set ->
        love.graphics.push!
        love.graphics.rotate angle
        shape!
        love.graphics.pop!

Constant.meta
  meta:
    name: 'love'
    summary: "LÖVE graphics."
    description: "
This module implements basic graphics using the [love2d game engine][love].

#### running

In order to use this module, the copilot has to be started in a specific way:

    $ love bin/alv-love <session.alv>

#### usage

The [love/draw][] ops can be used to draw one or more `love/shape`s in a fixed
stacking order. `love/shape`s can be created using [love/rectangle][] etc, and
positioned and styled using the modifier ops like [love/translate][],
[love/color][] and so on. All modifier ops take the shape as the last input and
output a modified shape, and can be used comfortably with the thread-last
macro [->>][]:

    (import* love math)
    (draw (->>
      (rectangle 'fill' 100 100)
      (color 1 0 0)
      (rotate (/ pi 4))
      (translate 150 150)))


[love]: https://love2d.org"

  value:
    :draw

    :rectangle

    :translate, :rotate
    :color
