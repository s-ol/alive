{ graphics: lg } = love
import Op from require 'base'
import Copilot from require 'copilot'

class out extends Op
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

copilot = Copilot arg[#arg], env

love.update = (dt) ->
  copilot\poll!
  env\update dt
 
love.draw = ->
  out.draw_all!

{
  :out
}
