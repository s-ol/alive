import Constant, Scope, Op, Tag from require 'alv'
import Copilot from require 'alv.copilot.base'
import Module, StringModule from require 'alv.module'
import Logger from require 'alv.logger'
import Error from require 'alv.error'
import RTNode from require 'alv.rtnode'
Logger\init 'error'

class TestPilot extends Copilot
  new: (code) =>
    super!

    if code
      @active_module = StringModule 'main', code
      @last_modules.__root = @active_module
      @tick!
    else
      @active_module = Module!
      @last_modules.__root = @active_module

  begin_eval: => @active_module.registry\begin_eval!
  end_eval: => @active_module.registry\end_eval!
  next_tick: => @T += 1

  require: (name) =>
    Error.wrap "loading module '#{name}'", ->
      ok, lua = pcall require, "alv-lib.#{name}"
      if ok
        RTNode result: Constant.wrap lua
      else
        error Error 'import', "module not found"

export COPILOT

{
  :TestPilot

  do_setup: ->
    COPILOT = TestPilot!
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
