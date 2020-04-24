require 'alv'
import Copilot from require 'alv.copilot'
import Module from require 'alv.module'
import Logger from require 'alv.logger'
Logger\init 'silent'

class TestModule extends Module

class TestCopilot extends Copilot
  new: =>
    @T = 0
    @active_module = Module!

  begin_eval: => @active_module.registry\begin_eval!
  end_eval: => @active_module.registry\end_eval!
  next_tick: => @T += 1

  require: =>
    error "not implemented"

export COPILOT

{
  :TestCopilot

  do_setup: ->
    COPILOT = TestCopilot!
    COPILOT\begin_eval!

  do_teardown: ->
    COPILOT\end_eval!
}
