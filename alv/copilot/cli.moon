----
-- CLI Copilot entrypoint.
--
-- @classmod CLICopilot
import Logger, version from require 'alv'
import parse_args, Copilot from require 'alv.copilot.base'
import sleep from require 'system'

class ColorLogger extends Logger
  new: (...) =>
    super ...
    @time_pref = ''

  set_time: (time) =>
    super time
    @time_pref = switch time
      when 'eval' then '\27[92m'
      when 'run' then '\27[0m'

  put: (msg) =>
    super @time_pref .. msg

class CLICopilot extends Copilot
  new: (arg) =>
    super parse_args arg, { nocolor: false, 'udp-server': false }
    assert @args[1], "no filename given"

  setup: =>
    if @args.nocolor
      Logger\init @args.log
    else
      ColorLogger\init @args.log

  run: =>
    @setup!

    while true
      @tick!
      sleep 1 / 1000

{
  :CLICopilot
}
