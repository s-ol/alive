----
-- löve Copilot entrypoint.
--
-- @classmod LoveCopilot
import CLICopilot from require 'alv.copilot.cli'

class LoveCopilot extends CLICopilot
  new: (arg) =>
    table.remove arg, 1
    super arg
    @drawlist = {}

  update: =>
    @tick!

  draw: =>
    for id, list in pairs @drawlist
      for fn in *list
        fn!

  run: =>
    @setup!

    love.draw = @\draw
    love.update = @\update

{
  :LoveCopilot
}
