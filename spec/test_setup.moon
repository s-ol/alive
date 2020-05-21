import Constant, Scope, Op, Tag from require 'alv'
import Copilot from require 'alv.copilot.base'
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

  invoke_op: (op, tail, scope=Scope!) ->
    import op_invoke from require 'alv.invoke'

    fake_cell =
      head: -> 'test_op'
      tail: -> tail
      tag: Tag.blank!

    op_invoke\eval_cell fake_cell, Scope!, Constant.wrap op
}
