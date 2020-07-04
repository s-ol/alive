----
-- CLI Copilot entrypoint.
--
-- @classmod CLICopilot
import Logger, version from require 'alv'
import parse_args, Copilot from require 'alv.copilot.base'
import sleep from require 'system'

class ColorLogger extends Logger
  set_time: (time) =>
    super time
    @stream\write switch time
      when 'eval' then '\27[92m'
      when 'run' then '\27[0m'

class CLICopilot extends Copilot
  new: (arg) =>
    super parse_args arg, { nocolor: false }
    assert @args[1], "no filename given"

  run: =>
    if @args.nocolor
      Logger\init @args.log
    else
      ColorLogger\init @args.log

    while true
      @tick!
      sleep 1 / 1000

{
  :CLICopilot
}
