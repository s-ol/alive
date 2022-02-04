----
-- Constant Value.
--
-- Implements the `Result` and `AST` inteface.
--
-- @classmod Constant
import Result, __eq from require 'alv.result.base'
import T from require 'alv.type'
import RTNode from require 'alv.rtnode'
import Error from require 'alv.error'
import scope, base from require 'alv.cycle'
import ancestor from require 'alv.util'

class Constant extends Result
--- Result interface
--
-- `Constant` implements the `Result` interface.
-- @section result

  --- return whether this Result was changed in the current tick.
  -- @treturn bool
  dirty: => false

  --- unwrap to the Lua type.
  --
  -- Asserts `@type == type` if `type` is given.
  --
  -- @tparam[opt] string type the type to check for
  -- @tparam[optchain] string msg message to throw if type don't match
  -- @treturn any `value`
  unwrap: (type, msg) =>
    assert type == @type, msg or "#{@} is not a #{type}" if type
    @value

  --- create a mutable copy of this stream.
  --
  -- Used to insulate eval-cycles from each other.
  --
  -- @treturn Constant
  fork: => @

  --- alias for `unwrap`.
  __call: (...) => @unwrap ...

  --- compare two values.
  --
  -- Compares two `SigStream`s by comparing their types and their Lua values.
  __eq: (other) => other.type == @type and @type\eq other.value, @value

  --- Result metatype.
  -- @tfield string metatype (`=`)
  metatype: '='

-- @section

--- AST interface
--
-- `Constant` implements the `AST` interface.
-- @section ast

  --- evaluate this literal constant.
  --
  -- Throws an error if `type` is not a literal (`num`, `str` or `sym`).
  -- Returns an eval-time const result for `num` and `str`.
  -- Resolves `sym`s in `scope` and returns a reference to them.
  --
  -- @tparam Scope scope the scope to evaluate in
  -- @treturn RTNode the evaluation result
  eval: (scope) =>
    switch @type
      when T.num, T.str
        RTNode result: @
      when T.sym
        Error.wrap "resolving symbol '#{@value}'", scope\get, @value
      else
        error "cannot evaluate #{@}"

  --- stringify this literal constant.
  --
  -- Throws an error if `raw` is not set.
  --
  -- @treturn string the exact string this stream was parsed from
  stringify: => @raw

  --- clone this literal constant.
  --
  -- @treturn SignStream self
  clone: (prefix) => @

--- static functions
-- @section static

  --- construct a new Constant.
  --
  -- @classmethod
  -- @tparam string type the type name
  -- @tparam any value the Lua value to be accessed through `unwrap`
  -- @tparam string raw the raw string that resulted in this value. Used by `parsing`.
  new: (type, @value, @raw) =>
    super type
    assert @value ~= nil, "Constant without value"

  unescape = (str) -> str\gsub '\\([\'"\\])', '%1'
  --- create a capture-function (for parsing with Lpeg).
  --
  -- @tparam string type the type name (one of `num`, `sym` or `str`)
  -- @tparam string sep the seperator char (only for `str`)
  @parse: (type, sep) =>
    switch type
      when 'num' then (match) -> @ T.num, (tonumber match), match
      when 'sym' then (match) -> @ T.sym, match, match
      when 'str' then (match) -> @ T.str, (unescape match), sep .. match .. sep

  --- wrap a Lua value.
  --
  -- Attempts to guess the type and wrap a Lua value.
  --
  -- @tparam any val the value to wrap
  -- @tparam[opt] string name the name of this value (for error logging)
  -- @treturn Constant
  @wrap: (val, name='(unknown)') ->
    typ = switch type val
      when 'number' then T.num
      when 'string' then T.str
      when 'table'
        if rawget val, '__base'
          -- a class
          switch ancestor val
            when base.Op then T.opdef
            when base.Builtin then T.builtin
            else
              error "#{name}: cannot wrap class '#{val.__name}'"
        elseif val.__class
          -- an instance
          switch ancestor val.__class
            when scope.Scope then T.scope
            when base.FnDef then T.fndef
            when Result then return val
            else
              error "#{name}: cannot wrap '#{val.__class.__name}' instance"
        else
          -- plain table
          val = scope.Scope.from_table val
          T.scope
      else
        error "#{name}: cannot wrap Lua type '#{type val}'"

    Constant typ, val

  --- create a constant number.
  -- @tparam number num the number
  -- @treturn Constant
  @num: (num) -> Constant T.num, num, tostring num

  --- create a constant string.
  -- @tparam string str the string
  -- @treturn Constant
  @str: (str) -> Constant T.str, str, "'#{str}'"

  --- create a constant symbol.
  -- @tparam string sym the symbol
  -- @treturn Constant
  @sym: (sym) -> Constant T.sym, sym, sym

  --- create a constant boolean.
  -- @tparam boolean bool the boolean
  -- @treturn Constant
  @bool: (bool) -> Constant T.bool, bool, tostring bool

  --- create a constant bang.
  -- @treturn Constant
  @bang: -> Constant T.bang, true

  --- wrap and document a value.
  --
  -- wraps `args.value` using `wrap`, then assigns `meta`.
  --
  -- @tparam table args table with keys `value` and `meta`
  -- @treturn Constant
  @meta: (args) ->
    if args.meta and args.meta.name and
       type(args.value) == "table" and
       args.value and args.value.__class and args.value.__parent
      args.value.__name = args.meta.name

    with Constant.wrap args.value
      .meta = args.meta if args.meta

{
  :Constant
}
