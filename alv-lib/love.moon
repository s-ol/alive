import Constant, Op, PureOp, Input, T, Array, any from require 'alv.base'

unpack or= table.unpack

vec2 = Array 2, T.num
vec3 = Array 3, T.num
vec4 = Array 4, T.num

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

    pattern = any['love/shape']*0
    setup: (inputs, scope) =>
      shapes = pattern\match inputs
      inputs = [Input.hot shape for shape in *shapes]
      inputs.num = Input.cold Constant.num #shapes
      super inputs

    tick: =>
      shapes = @unwrap_all!
      for i=1, shapes.num do shapes[i] or= ->
      COPILOT.drawlist[@state] = shapes

    destroy: =>
      COPILOT.drawlist[@state] = nil

rectangle = Constant.meta
  meta:
    name: 'rectangle'
    summary: "create a rectangle shape."
    examples: { '(love/rectangle mode size)', '(love/rectangle mode w h)' }

  value: class extends PureOp
    pattern: any.str + (any(vec2) / (any.num + any.num))
    type: T['love/shape']

    tick: =>
      { mode, size } = @unwrap_all!
      { w, h } = size
      x, y = -w/2, -h/2

      @out\set ->
        love.graphics.rectangle mode, x, y, w, h

color = Constant.meta
  meta:
    name: 'color'
    summary: "set color of a shape."
    examples: { '(love/color r g b [a] shape)' }

  value: class extends PureOp
    pattern: any.num\rep(3, 4) + any['love/shape']
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
    examples: { '(love/translate [delta] shape)', '(love/translate x y shape)' }

  value: class extends PureOp
    pattern: (any(vec2) / (any.num + any.num)) + any['love/shape']
    type: T['love/shape']

    tick: =>
      { pos, shape } = @unwrap_all!
      { x, y } = pos

      @out\set ->
        love.graphics.push!
        love.graphics.translate x, y
        shape!
        love.graphics.pop!

rotate = Constant.meta
  meta:
    name: 'rotate'
    summary: "rotate a shape."
    examples: { '(love/rotate angle shape)' }

  value: class extends PureOp
    pattern: any.num + any['love/shape']
    type: T['love/shape']

    tick: =>
      { angle, shape } = @unwrap_all!

      @out\set ->
        love.graphics.push!
        love.graphics.rotate angle
        shape!
        love.graphics.pop!

scale = Constant.meta
  meta:
    name: 'scale'
    summary: "scale a shape."
    examples: { '(love/scale scale shape)', '(love/scale sx [sy] shape)' }

  value: class extends PureOp
    pattern: (any(vec2) / (any.num + -any.num)) + any['love/shape']
    type: T['love/shape']

    tick: =>
      { pos, shape } = @unwrap_all!
      { sx, sy } = pos

      @out\set ->
        love.graphics.push!
        love.graphics.scale sx, sy
        shape!
        love.graphics.pop!

shear = Constant.meta
  meta:
    name: 'shear'
    summary: "shear a shape."
    examples: { '(love/shear x y shape)' }

  value: class extends PureOp
    pattern: (any(vec2) / (any.num + any.num)) + any['love/shape']
    type: T['love/shape']

    tick: =>
      { pos, shape } = @unwrap_all!
      { sx, sy } = pos

      @out\set ->
        love.graphics.push!
        love.graphics.shear sx, sy
        shape!
        love.graphics.pop!

mouse_pos = Constant.meta
  meta:
    name: 'mouse-pos'
    summary: "outputs current mouse position."
    examples: { '(love/mouse-pos)' }

  value: class extends Op
    new: (...) =>
      super ...
      @out or= vec2\mk_evt!
      @state = {}

    setup: =>
      super io: Input.hot T.bang\mk_evt!

    poll: =>
      x, y = love.mouse.getPosition!
      if x != @state.x or y != @state.y
        @state.x, @state.y = x, y
        if not @inputs.io\dirty!
          @inputs.io.result\set true
          true

    tick: =>
      @out\set { @state.x, @state.y }

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

    :translate, :rotate, :scale, :shear
    :color

    'mouse-pos': mouse_pos
