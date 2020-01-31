{ graphics: lg } = love
import Registry from require 'registry'
import Copilot from require 'copilot'
import Constant, OP from require 'base'

env = Registry!
copilot = Copilot arg[#arg], env

env.globals.lfo = class LFO extends OP
  tau = math.pi * 2
  new: (...) =>
    super ...
    @phase = 0

  setup: (@speed, @wave=Constant 'sin') =>

  update: (dt) =>
    @phase += dt * @speed\get!
    @value = switch @wave\get!
      when 'sin' then .5 + .5 * math.cos @phase * tau
      when 'saw' then @phase % 1
      when 'tri' then math.abs (2*@phase % 2) - 1
      else error "unknown wave type"

env.globals.tick = class Tick extends OP
  new: (...) =>
    super ...
    @phase = 0

  setup: (@speed, @wave=Constant 'sin') =>

  update: (dt) =>
    @phase += dt / @speed\get!
    @value = math.floor @phase

env.globals.pick = class Pick extends OP
  setup: (@i, ...) =>
    @choices = { ... }

  update: =>
    i = 1 + (math.floor @i\get!) % #@choices
    @value = @choices[i]\get!

env.globals.mix = class Mix extends OP
  setup: (@a, @b, @i) =>

  update: (dt) =>
    i = @i\get!
    @value = i*@b\get! + (1-i)*@a\get!

env.globals['gui/out'] = class Out extends OP
  setup: (name, @chld) =>
    @@instances[@name] = nil if @name
    @name = name\getc!
    @@instances[@name] = @

  update: =>
    @value = @chld\get!

  destroy: =>
    @@instances[@name] = nil

  MARGIN = 16
  WIDTH = 24
  HEIGHT = 120 
  @instances: {}
  @draw_all: ->
    outs = [name for name in pairs @@instances]
    table.sort outs

    x = MARGIN
    lg.setColor 1, 1, 1
    for name in *outs
      value = @@instances[name].value * HEIGHT
      lg.rectangle 'line', x, MARGIN, WIDTH, HEIGHT
      lg.rectangle 'fill', x, MARGIN + HEIGHT - value, WIDTH, value
      lg.print name, x, MARGIN + HEIGHT + MARGIN
      x += WIDTH + MARGIN

love.update = (dt) ->
  copilot\patch!
  env\update dt
 
love.draw = ->
  Out.draw_all!
