import Constant, Op, PureOp, Input, Error, T, Array, any from require 'alv.base'

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

no_shape = Constant.meta
  meta:
    name: 'no-shape'
    summary: "invisible null shape."

  value: T['love/shape']\mk_const ->

circle = Constant.meta
  meta:
    name: 'circle'
    summary: "create a circle shape."
    examples: { '(love/circle mode radius [segments])' }

  value: class extends PureOp
    pattern: any.str + any.num + -any.num
    type: T['love/shape']

    tick: =>
      { mode, radius, segments } = @unwrap_all!

      @out\set ->
        love.graphics.circle mode, 0, 0, radius, segments

ellipse = Constant.meta
  meta:
    name: 'ellipse'
    summary: "create a ellipse shape."
    examples: { '(love/ellipse mode size [segments])', '(love/ellipse mode rx ry [segments])' }

  value: class extends PureOp
    pattern: any.str + (any(vec2) / (any.num + any.num)) + -any.num
    type: T['love/shape']

    tick: =>
      { mode, size, segments } = @unwrap_all!
      { rx, ry } = size

      @out\set ->
        love.graphics.ellipse mode, 0, 0, rx, ry, segments

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

text = Constant.meta
  meta:
    name: 'text'
    summary: "create a text shape."
    examples: { '(love/text str [align] [font])' }
    description: "
Create a shape that draws the text `str` with font `font` (or the default font).
`align` should be on of the following strings:
- `center` (the default)
- `left`
- `right`"


  value: class extends PureOp
    pattern: any.str + -any.str + -any['love/font']
    type: T['love/shape']

    tick: =>
      { text, align, font } = @unwrap_all!

      wm = switch align or 'center'
        when 'left' then 0
        when 'center' then -0.5
        when 'right' then -1
        else
          error Error 'argument', "unknown text alignment '#{align}'"

      @out\set ->
        font or= love.graphics.getFont!
        width = font\getWidth text
        height = font\getHeight!
        love.graphics.print text, font, width*wm, -height/2

color = Constant.meta
  meta:
    name: 'color'
    summary: "set color of a shape."
    examples: { '(love/color color shape)', '(love/color r g b [a] shape)' }

  value: class extends PureOp
    pattern: (any(vec3) / any(vec4) / any.num\rep(3, 4)) + any['love/shape']
    type: T['love/shape']

    tick: =>
      { color, shape } = @unwrap_all!
      { r, g, b, a } = color

      @out\set ->
        love.graphics.setColor r, g, b, a
        shape!
        love.graphics.setColor 1, 1, 1

line_width = Constant.meta
  meta:
    name: 'line-width'
    summary: "set line-width of a shape."
    examples: { '(love/line-width width shape)' }

  value: class extends PureOp
    pattern: any.num + any['love/shape']
    type: T['love/shape']

    tick: =>
      { width, shape } = @unwrap_all!

      @out\set ->
        love.graphics.setLineWidth width
        shape!
        love.graphics.setLineWidth 1

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

    'no-shape': no_shape
    :circle, :ellipse, :line, :rectangle, :text

    :translate, :rotate, :scale, :shear
    :color, 'line-width': line_width

    'mouse-pos': mouse_pos
