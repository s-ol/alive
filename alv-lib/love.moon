import Constant, Op, PureOp, Input, Error, T, Array, any, sig from require 'alv.base'
import RTNode from require 'alv'

unpack or= table.unpack

vec2 = Array 2, T.num
vec3 = Array 3, T.num
vec4 = Array 4, T.num

class DrawId
  new: =>

draw = Constant.meta
  meta:
    name: 'draw'
    summary: "draw one or more love/shape shapes."
    examples: { '(love/draw shape1 …)', '(love/draw shapes)' }

  value: class extends Op
    new: (...) =>
      super ...
      @state or= DrawId!

    pattern = any['love/shape']*0
    setup: (inputs, scope) =>
      if #inputs == 1
        only = inputs[1]
        type = only\type!
        if type.__class == Array and type.type == T['love/shape']
          super Input.hot only
          return

      shapes = pattern\match inputs
      inputs = [Input.hot shape for shape in *shapes]
      inputs.num = Input.cold Constant.num #shapes
      super inputs

    tick: =>
      shapes = @unwrap_all!
      num = shapes.num or #shapes
      for i=1, num do shapes[i] or= ->
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
      { col, shape } = @unwrap_all!
      { r, g, b, a } = col

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
    description: "vec2~ stream of mouse position."

  value: class extends Op
    setup: =>
      @out = COPILOT.mouse_pos
      super Input.hot @out

    poll: =>

mouse_delta = Constant.meta
  meta:
    name: 'mouse-delta'
    summary: "outputs mouse move events."
    examples: { '(love/mouse-delta)' }
    description: "vec2! stream of mouse movements."

  value: class extends Op
    setup: =>
      @out = COPILOT.mouse_delta
      super Input.hot @out

    poll: =>
  
mouse_presses = Constant.meta
  meta:
    name: 'mouse-presses'
    summary: "outputs mouse press events."
    examples: { '(love/mouse-presses)', '(love/mouse-presses button)' }
    description: "With no arguments, outputs a !-stream of press events with the following keys:
- `pos` (vec2): x/y position of mouse
- `button` (num): mouse button number

If `button` is passed, outputs a vec2! stream."

  value: class extends Op
    setup: (inputs) =>
      button = (-sig.num)\match inputs
      event = Input.hot COPILOT.mouse_presses

      if button
        super :event, button: Input.cold button
        @out = vec2\mk_evt!
      else
        super :event
        @out = COPILOT.mouse_presses

    poll: =>

    tick: =>
      { :button, :event } = @unwrap_all!
      if event and event.button == button
        @out\set event.pos

mouse_releases = Constant.meta
  meta:
    name: 'mouse-releases'
    summary: "outputs mouse release events."
    examples: { '(love/mouse-releases)', '(love/mouse-releases button)' }
    description: "With no arguments, outputs a !-stream of release events with the following keys:
- `pos` (vec2): x/y position of mouse
- `button` (num): mouse button number

If `button` is passed, outputs a vec2! stream."

  value: class extends Op
    setup: (inputs) =>
      button = (-sig.num)\match inputs
      event = Input.hot COPILOT.mouse_releases

      if button
        super :event, button: Input.cold button
        @out = vec2\mk_evt!
      else
        super :event
        @out = COPILOT.mouse_releases

    poll: =>

    tick: =>
      { :button, :event } = @unwrap_all!
      if event and event.button == button
        @out\set event.pos

mouse_down = Constant.meta
  meta:
    name: 'mouse-down?'
    summary: "checks whether a mouse button is down."
    examples: { '(love/mouse-down? [button])' }
    description: "checks whether `button` is down and returns a bool ~-stream.

`button` should be a num~ stream and defaults to `1` (the left mouse button)."

  value: class extends Op
    pattern = -sig.num
    setup: (inputs) =>
      button = pattern\match inputs

      super
        button: Input.hot button or T.num\mk_const 1
        press: Input.hot COPILOT.mouse_presses
        release: Input.hot COPILOT.mouse_releases

      @update_out '~', T.bool, false

    poll: =>

    tick: =>
      { :button, :press, :release } = @unwrap_all!
      if button and @inputs.button\dirty!
        @state = false

      if press and (not button or press.button == button)
        @state = true

      if release and (not button or release.button == button)
        @state = false

      @out\set @state

wheel_delta = Constant.meta
  meta:
    name: 'wheel-delta'
    summary: "outputs mouse wheel move events."
    examples: { '(love/wheel-delta)' }
    description: "vec2! stream of mouse wheel movements."

  value: class extends Op
    setup: (inputs) =>
      assert #inputs == 0, Error "argument", "no arguments expected"
      @out = COPILOT.wheel_delta
      super Input.hot @out

    poll: =>

key_presses = Constant.meta
  meta:
    name: 'key-presses'
    summary: "outputs key press events."
    examples: { '(love/key-presses)', '(love/key-presses key)' }
    description: "With no arguments, outputs a str! stream of key names.

If `key` is passed, outputs a bang! stream."

  value: class extends Op
    setup: (inputs) =>
      key = (-sig.str)\match inputs
      event = Input.hot COPILOT.key_presses

      if key
        super :event, key: Input.cold key
        @out = T.bang\mk_evt!
      else
        super :event
        @out = COPILOT.key_presses

    poll: =>

    tick: =>
      { :key, :event } = @unwrap_all!
      if event and event == key
        @out\set true

key_releases = Constant.meta
  meta:
    name: 'key-releases'
    summary: "outputs key release events."
    examples: { '(love/key-releases)', '(love/key-releases key)' }
    description: "With no arguments, outputs a str! stream of key names.

If `key` is passed, outputs a bang! stream."

  value: class extends Op
    setup: (inputs) =>
      key = (-sig.str)\match inputs
      event = Input.hot COPILOT.key_releases

      if key
        super :event, key: Input.cold key
        @out = T.bang\mk_evt!
      else
        super :event
        @out = COPILOT.key_releases

    poll: =>

    tick: =>
      { :key, :event } = @unwrap_all!
      if event and event == key
        @out\set true


key_down = Constant.meta
  meta:
    name: 'key-down?'
    summary: "checks whether a key is down."
    examples: { '(love/key-down? key)' }
    description: "checks whether `key` is down and returns a bool ~-stream.

`key` should be a str~ stream."

  value: class extends Op
    pattern = sig.str
    setup: (inputs) =>
      key = pattern\match inputs

      super
        key: Input.hot key
        press: Input.hot COPILOT.key_presses
        release: Input.hot COPILOT.key_releases

      @update_out '~', T.bool, false

    poll: =>

    tick: =>
      { :key, :press, :release } = @unwrap_all!
      if key and @inputs.key\dirty!
        @state = false

      if press and (not key or press == key)
        @state = true

      if release and (not key or release == key)
        @state = false

      @out\set @state

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
    'mouse-delta': mouse_delta
    'mouse-presses': mouse_presses
    'mouse-releases': mouse_releases
    'mouse-down?': mouse_down
    'wheel-data': wheel_delta
    'key-presses': key_presses
    'key-releases': key_releases
    'key-down?': key_down
