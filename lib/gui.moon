assert love, "this module only works from within love2d!"
{ graphics: lg, keyboard: lk } = love

import Op from require 'core'
import Copilot from require 'copilot'
import Logger from require 'logger'

class out extends Op
  @doc: "(out name-str value) - show the output

display value as a bar"

  setup: (name, @chld) =>
    @@instances[@name] = nil if @name
    @name = name\const!\unwrap!
    @@instances[@name] = @

  update: (dt) =>
    @value = @chld\unwrap!

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

class key extends Op
  @doc: "(key name-str) - gate from keypress"

  setup: (@key) =>
    assert @key
    @out = Stream 'bool', false
    @out

  update: (dt) =>
    @out\set lk.isDown @key\unwrap!

arguments, k = {}
for a in *arg
  if match = a\match '^%-%-(.*)'
    k = match
    arguments[k] = true
  elseif k
    arguments[k] = a
    k = nil
  else
    table.insert arguments, a

Logger.init arguments.log

copilot = Copilot arguments[#arguments]

love.update = (dt) ->
  copilot\update dt
 
love.draw = ->
  out.draw_all!

{
  :out
  :key
}
