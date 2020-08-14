----
-- Per-file execution context.
--
-- @module module
import Registry from require 'alv.registry'
import Error from require 'alv.error'
import Scope from require 'alv.scope'
import program from require 'alv.parsing'
builtins = require 'alv.builtins'

--- Base class for Modules.
-- @type Module
class Module
  --- create a new Module.
  -- @classmethod
  new: =>
    @registry = Registry!

  --- check when the module source has last changed.
  -- @function poll
  -- @treturn number timestamp of last change

  --- get the module name.
  -- @function name
  -- @tparam[default=false] boolean full path
  -- @treturn string

  --- get the module contents.
  -- @function slurp
  -- @treturn string

  --- update the module contents.
  -- @function spit
  -- @tparam string str the updated contents

  --- start an evaluation cycle.
  --
  -- If the module has already been evaluated this tick, this is a noop.
  -- Otherwise, register the module with the `Copilot`. Updates `root`.
  eval: =>
    @registry\begin_eval!
    @ast = Error.wrap "parsing '#{@name true}'", -> program\match @slurp!
    assert @ast, Error 'syntax', "failed to parse"

    scope = Scope builtins
    @root = Error.wrap "evaluating '#{@name true}'", @ast\eval, scope, @registry

  --- rollback the last evaluation cycle.
  rollback: => @registry\rollback_eval!

  --- finish the last evaluation cycle.
  finish: =>
    tags_changed = @registry\end_eval!
    if tags_changed
      @spit @ast\stringify!

  --- destroy this module.
  destroy: =>
    @registry\destroy!

  __tostring: => "<#{@@__name} #{@name!}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

  --- the last updated AST tree for this module.
  -- @tfield ?AST ast

  --- the runtime graph root of this module.
  -- @tfield ?RTNode root

--- Module type for modules loaded from the filesystem.
-- @type FSModule
class FSModule extends Module
  --- create a new FSModule.
  -- @classmethod
  -- @tparam string file filepath
  new: (@file) =>
    super!

  slurp: =>
    file = assert (io.open @file, 'r'), Error 'io', "couldn't open '#{@file}'"
    with file\read '*all'
      file\close!

  spit: (str) =>
    file = io.open @file, 'w'
    file\write str
    file\close!

  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    assert mode == 'file', Error 'io', "not a file: '#{@file}'"
    modification

  name: (full) =>
    if full then @file else @file\match '([^/\\]+)$'

--- Module type for modules loaded from RAM.
-- @type StringModule
class StringModule extends Module
  --- create a new StringModule.
  -- @classmethod
  -- @tparam string name_ module name
  -- @tparam string source module source code
  new: (@name_, @source) =>
    super!
    @updated = os.time!

  slurp: => @source

  spit: (str) =>
    @source = str
    @updated = os.time!

  poll: => @updated

  name: => @name_

{
  :Module
  :FSModule
  :StringModule
}
