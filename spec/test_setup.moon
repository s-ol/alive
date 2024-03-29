import Constant, Scope, Op, Tag from require 'alv'
import Copilot from require 'alv.copilot.base'
import Module, StringModule from require 'alv.module'
import Logger from require 'alv.logger'
import Error from require 'alv.error'
import RTNode from require 'alv.rtnode'
busted = require "busted"

Logger\init 'error'
os.time = do
  t = 0
  ->
    t += 1
    t

export COPILOT

class TestPilot extends Copilot
  new: (code='', @preamble='') =>
    super!

    COPILOT = @

    if code.__class == Module
      @active_module = code
      @last_modules.__root = @active_module
    else
      @active_module = StringModule 'main', @preamble .. code
      @last_modules.__root = @active_module
      @tick!

  begin_eval: => @active_module.registry\begin_eval!
  end_eval: => @active_module.registry\end_eval!
  next_tick: => @T += 1

  eval_once: (code) =>
    @active_module\spit @preamble .. code
    ok, err = pcall @tick, @
    if not ok
      if (type err) == 'table' and err.__class == Error and err.kind == 'assertion'
        busted.fail err, 0

      error err, 0

    @active_module.root

  --- poll for changes and tick.
  tick: =>
    return unless @last_modules.__root

    @T += 1

    ok, err = @poll!
    if not ok
      error err

    root = @last_modules.__root
    if root and root.root
      L\set_time 'run'
      ok, error = Error.try "updating", ->
        root.root\poll_io!
        root.root\tick!
      if not ok
        error

  require: (name) =>
    Error.wrap "loading module '#{name}'", ->
      ok, result = pcall require, "alv-lib.#{name}"
      if ok
        result = RTNode :result unless result.__class == RTNode
        result
      else
        error Error 'import', "module not found"

{
  :TestPilot

  do_setup: ->
    TestPilot Module!
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
