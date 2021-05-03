----
-- löve Copilot entrypoint.
--
-- @classmod LoveCopilot
import CLICopilot from require 'alv.copilot.cli'
import T, Struct, Array from require 'alv.base'

export COPILOT

vec2 = Array 2, T.num
mouse_evt = Struct pos: vec2, button: T.num

class LoveCopilot extends CLICopilot
  new: (arg) =>
    table.remove arg, 1
    super arg

    @drawlist = {}
    @mouse_pos = vec2\mk_sig { love.mouse.getPosition! }
    @mouse_delta = vec2\mk_evt!
    @mouse_presses = mouse_evt\mk_evt!
    @mouse_releases = mouse_evt\mk_evt!
    @wheel_delta = vec2\mk_evt!
    @key_presses = T.str\mk_evt!
    @key_releases = T.str\mk_evt!
    @textinput = T.str\mk_evt!

  draw: =>
    love.graphics.origin!
    love.graphics.clear!

    for id, list in pairs @drawlist
      for fn in *list
        fn!

    love.graphics.present!

  run: =>
    @setup!

    love.run = ->
      return ->
        love.event.pump!
        did_tick = false
        for name, a,b,c,d,e,f in love.event.poll!
          COPILOT = @
          switch name
            when 'quit'
              return a or 0
            when 'mousemoved'
              @mouse_pos\set { a, b }
              @mouse_delta\set { c, d }, true
            when 'mousepressed'
              @mouse_presses\set { pos: { a, b }, button: c }, true
            when 'mousereleased'
              @mouse_releases\set { pos: { a, b }, button: c }, true
            when 'wheelmoved'
              @wheel_delta\set { a, b }, true
            when 'keypressed'
              @key_presses\set a, true
            when 'textinput'
              @textinput\set a, true
            when 'keyreleased'
              @key_releases\set a, true
            --else
            --  print "unhandled: '#{name}'", a,b,c,d,e,f

          COPILOT = nil
          did_tick = true
          @tick!

        @tick! unless did_tick
        @draw!

        love.timer.sleep 0.001 if love.timer

{
  :LoveCopilot
}
