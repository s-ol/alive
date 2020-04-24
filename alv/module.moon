----
-- Per-file execution context.
--
-- @classmod Module
import Registry from require 'alv.registry'
import Error from require 'alv.error'
import Scope from require 'alv.scope'
import program from require 'alv.parsing'
builtin = require 'alv.builtin'

slurp = (file) ->
  file = assert (io.open file, 'r'), Error 'io', "couldn't open '#{file}'"
  with file\read '*all'
    file\close!

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

class Module
--- static functions
-- @section static

  --- create a new Module.
  -- @classmethod
  new: (@file) =>
    @registry = Registry!
    @last_modification = 0

--- members
-- @section members

  --- check whether file was changed.
  -- @treturn bool whether the file was changed since the last call
  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    assert mode == 'file', Error 'io', "not a file: '#{file}'"

    if @last_modification < modification
      true

  --- start an evaluation cycle.
  --
  -- If the module has already been evaluated this tick, this is a noop.
  -- Otherwise, register the module with the `Copilot`. Updates `root`.
  eval: =>
    @last_modification = os.time!
    @ast = Error.wrap "parsing '#{@file}'", -> program\match slurp @file
    assert @ast, Error 'syntax', "failed to parse"

    scope = Scope builtin
    @registry\begin_eval!
    @root = Error.wrap "evaluating '#{@file}'", @ast\eval, scope, @registry
    @registry\release!

  --- rollback the last evaluation cycle.
  rollback: => @registry\rollback_eval!

  --- finish the last evaluation cycle.
  finish: =>
    tags_changed = @registry\end_eval!
    if tags_changed
      spit @file, @ast\stringify!

  --- destroy this module.
  destroy: =>
    @registry\destroy!

  __tostring: => "<Module #{@file}>"

  --- the last updated AST tree for this module.
  -- @tfield ?AST ast

  --- the root Result of this module.
  -- @tfield ?Result root

{
  :Module
}
