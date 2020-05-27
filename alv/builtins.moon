----
-- Builtin `Builtin`s and `Op`s.
--
-- Please see the [reference](../../reference/index.html#builtins) for
-- documentation.
--
-- @module builtins
import Builtin, Op, PureOp, T, FnDef, Input, const, val, evt, Struct, Array
  from require 'alv.base'
import Constant from require 'alv.result'
import Error from require 'alv.error'
import RTNode from require 'alv.rtnode'
import Cell from require 'alv.cell'
import Scope from require 'alv.scope'
import Tag from require 'alv.tag'
import op_invoke from require 'alv.invoke'
lfs = require 'lfs'

doc = Constant.meta
  meta:
    name: 'doc'
    summary: "Print documentation in console."
    examples: { '(doc sym)' }
    description: "Print the documentation for `sym` to the console"

  value: class extends Builtin
    format_meta = =>
      str = @summary
      if @examples
        for example in *@examples
          str ..= '\n' .. example
      if @description
        str ..= '\n' .. @description\match '^\n*(.+)\n*$'
      str

    eval: (scope, tail) =>
      assert #tail == 1, "'doc' takes exactly one parameter"

      node = L\push tail[1]\eval, scope
      with RTNode children: { def }
        meta = node.result.meta
        L\print "(doc #{tail[1]}):\n#{format_meta meta}\n"

def = Constant.meta
  meta:
    name: 'def'
    summary: "Declare symbols in current scope."
    examples: { '(def sym1 val-expr1 [sym2 val-expr2…])' }
    description: "
Define the symbols `sym1`, `sym2`, … to resolve to the values of `val-expr1`,
`val-expr2`, …."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 1, "'def' requires at least 2 arguments"
      assert #tail % 2 == 0, "'def' requires an even number of arguments"

      children = L\push ->
        return for i=1,#tail,2
          name, val_expr = tail[i], tail[i+1]
          name = name\unwrap T.sym

          with val_expr\eval scope
            scope\set name, \make_ref!

      RTNode :children

use = Constant.meta
  meta:
    name: 'use'
    summary: "Merge scopes into current scope."
    examples: { '(use scope1 [scope2…])' }
    description: "
Copy all symbol definitions from `scope1`, `scope2`, … to the current scope.
All arguments have to be evaltime constant."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      for child in *tail
        node = L\push child\eval, scope
        value = node\const!
        scope\use value\unwrap 'scope', "'use' only works on scopes"

      RTNode!

require_ = Constant.meta
  meta:
    name: 'require'
    summary: "Load a module."
    examples: { '(require name)' }
    description: "Load a module and return its scope."

  value: class extends Builtin
    eval: (scope,  tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'require' takes exactly one parameter"

      node = L\push tail[1]\eval, scope
      name = node\const!\unwrap 'str'

      L\trace @, "loading module #{name}"
      COPILOT\require name

import_ = Constant.meta
  meta:
    name: 'import'
    summary: "Require and define modules."
    examples: { '(import sym1 [sym2…])' }
    description: "
Requires modules `sym1`, `sym2`, … and define them as `sym1`, `sym2`, … in the
current scope."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 0, "'import' requires at least one arguments"

      children = for i, child in ipairs tail
        name = child\unwrap T.sym
        with COPILOT\require name
          scope\set name, \make_ref!
      RTNode :children

import_star = Constant.meta
  meta:
    name: 'import*'
    summary: "Require and use modules."
    examples: { '(import* sym1 [sym2…])' }
    description: "
Requires modules `sym1`, `sym2`, … and merges them into the current scope."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 0, "'import' requires at least one arguments"

      children = for i, child in ipairs tail
        with COPILOT\require child\unwrap T.sym
          scope\use .result\unwrap T.scope
      RTNode :children

export_ = Constant.meta
  meta:
    name: 'export'
    summary: "Evaluate definitions in a new scope and return it."
    examples: { '(export expr1 [expr2…])' }
    description: "
Evaluate `expr1`, `expr2`, … in a new Scope and return scope."

  value: class extends Builtin
    eval: (scope, tail) =>
      new_scope = Scope scope
      children = [expr\eval new_scope for expr in *tail]
      RTNode :children, result: Constant.wrap new_scope

export_star = Constant.meta
  meta:
    name: 'export*'
    summary: "Export specific symbol definitions as a module/scope."
    examples: { '(export* sym1 [sym2…])', '(export*)' }
    description: "
Creates a scope containing the symbols `sym1`, `sym2`, … and returns it.

Copies the containing scope if no symbols are given."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      new_scope = Scope!

      children = if #tail == 0
        for k,node in pairs scope.values
          new_scope\set k, node
          node
      else
        for child in *tail
          name = child\unwrap T.sym
          with node = scope\get name
            new_scope\set name, node

      RTNode :children, result: Constant.wrap new_scope

fn = Constant.meta
  meta:
    name: 'fn'
    summary: "Declare a function."
    examples: { '(fn (p1 [p2…]) body-expr)' }
    description: "
The symbols `p1`, `p2`, ... will resolve to the arguments passed when the
function is invoked."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 2, "'fn' takes exactly two arguments"
      { params, body } = tail

      assert params.__class == Cell, "'fn's first argument has to be an expression"
      param_symbols = for param in *params.children
        assert param.type == T.sym, "function parameter declaration has to be a symbol"
        param

      RTNode result: with Constant.wrap FnDef param_symbols, body, scope
        .meta = {
          summary: "(user defined function)"
          examples: { "(??? #{table.concat [p! for p in *param_symbols], ' '})" }
        }

defn = Constant.meta
  meta:
    name: 'defn'
    summary: "Define a function."
    examples: { '(defn name-sym (p1 [p2…]) body-expr)' }
    description: "
Declare a function and define it as `name-sym` in the current scope.
The symbols `p1`, `p2`, ... will resolve to the arguments passed when the
function is invoked."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 3, "'defn' takes exactly three arguments"
      { name, params, body } = tail

      name = name\unwrap T.sym
      assert params.__class == Cell, "'defn's second argument has to be an expression"
      param_symbols = for param in *params.children
        assert param.type == T.sym, "function parameter declaration has to be a symbol"
        param

      result = with Constant.wrap FnDef param_symbols, body, scope
        .meta =
          :name
          summary: "(user defined function)"
          examples: { "(#{name} #{table.concat [p! for p in *param_symbols], ' '})" }

      scope\set name, RTNode :result
      RTNode!

do_expr = Constant.meta
  meta:
    name: 'do'
    summary: "Evaluate multiple expressions in a new scope."
    examples: { '(do expr1 [expr2…])' }
    description: "
Evaluate `expr1`, `expr2`, … and return the value of the last expression."

  value: class extends Builtin
    eval: (scope, tail) =>
      scope = Scope scope
      children = [expr\eval scope for expr in *tail]
      last = children[#children]
      RTNode :children, result: last and last.result

if_ = Constant.meta
  meta:
    name: 'if'
    summary: "Make an evaltime const choice."
    examples: { '(if bool then-expr [else-expr])' }
    description: "
`bool` has to be an evaltime constant. If it is truthy, this expression is equivalent
to `then-expr`, otherwise it is equivalent to `else-xpr` if given, or nil otherwise."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail >= 2, "'if' needs at least two parameters"
      assert #tail <= 3, "'if' needs at most three parameters"

      { xif, xthen, xelse } = tail

      xif = L\push xif\eval, scope
      xif = xif\const!\unwrap!

      if xif
        xthen\eval scope
      elseif xelse
        xelse\eval scope

trace_ = Constant.meta
  meta:
    name: 'trace='
    summary: "Trace an expression's value at evaltime."
    examples: { '(trace= expr)' }

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      with node = L\push tail[1]\eval, scope
        L\print "trace! #{tail[1]\stringify 2}: #{node.result}"

trace = Constant.meta
  meta:
    name: 'trace'
    summary: "Trace an expression's values at runtime."
    examples: { '(trace expr)' }

  value: class extends Builtin
    class traceOp extends Op
      setup: (inputs) =>
        super
          prefix: Input.cold inputs[1]
          value: Input.hot inputs[2]

      tick: =>
        L\print "trace #{@inputs.prefix!}: #{@inputs.value.result}"

    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, {
        Constant.literal T.opdef, traceOp, 'trace'
        Constant.str tail[1]\stringify 2
        tail[1]
      }
      inner\eval scope

print_ = Constant.meta
  meta:
    name: 'print'
    summary: "Print string values."
    examples: { '(print str)' }

  value: class extends Op
    setup: (inputs) =>
      value = (val.str / evt.str)\match inputs
      super value: Input.hot value

    tick: =>
      if @inputs.value\metatype! == 'event'
        for msg in *@inputs.value!
          L\print msg
      else
        L\print @inputs.value!

to_const = Constant.meta
  meta:
    name: '='
    summary: "Assert expression is constant."
    examples: { '(= val)' }
    description: "Asserts that `val` is a constant expression and returns it."
  value: class extends Op
    setup: (inputs) =>
      super {}
      input = const!\match inputs
      @out = input\type!\mk_const input.result!

to_sig = Constant.meta
  meta:
    name: '~'
    summary: "Cast to ~-stream."
    examples: { '(~ event initial)' }
    description: "
Casts !-stream to ~-stream by always reproducing the last received value.
Since ~-streams cannot be emtpy, specifying an `initial` value is necessary."
  value: class extends Op
    setup: (inputs) =>
      { event, initial } = (evt! + val!)\match inputs
      assert event\type! == initial\type!,
        Error 'argument', "~ arguments have to be of the same type"

      super event: Input.hot event

      if not @out or @out.type != input\type!
        @out = event\type!\mk_sig initial.result!

    tick: => @out\set @inputs.event!

to_evt = Constant.meta
  meta:
    name: '!'
    summary: "Cast to !-stream."
    examples: { '(! val)', '(! sig trig)' }
    description: "Casts anything to a !-stream depending on arguments:

- if `val` is a ~-stream, emits events on changes.
- if `val` is a !-stream, emits a bang for each incoming event.
- if `trig` is given, samples `sig` as a new event when `trig` arrives."
  value: class extends Op
    pattern = (val! + evt.bang) / (val! / evt!)\rep(1,1)
    setup: (inputs) =>
      { sig, trig } = pattern\match inputs
      if trig
        super
          trig: Input.hot trig
          sig: Input.cold sig
      elseif sig\metatype! == '!'
        super
          trig: Input.hot sig
          sig: Input.cold Constant.bang true
      else
        super sig: Input.hot sig
      @out = @inputs.sig\type!\mk_evt!

    tick: =>
      @out\set @inputs.sig!

array = Constant.meta
  meta:
    name: 'array'
    summary: "Construct an array."
    examples: { '(array a b c…)' }
    description: "Produces an array of values."

  value: do
    any = val! / evt!

    class extends PureOp
      pattern: any!*0
      type: (args) => Array #args, args[1]\type!

      tick: =>
        args = @unwrap_all!
        @out\set args

struct = Constant.meta
  meta:
    name: 'struct'
    summary: "Construct an struct."
    examples: { '(struct key1 val1 [key2 val2…])' }
    description: "Produces an struct of values."

  value: do
    key = const.str / const.sym
    val = val! / evt!
    pair = (key + val)\named 'key', 'val'

    class extends PureOp
      pattern: pair*0
      type: (pairs) =>
        Struct {key.result!, val\type! for {:key, :val} in *pairs}

      tick: =>
        pairs = @unwrap_all!
        @out\set {key, val for {:key, :val} in *pairs}

get = Constant.meta
  meta:
    name: 'get'
    summary: "Index into Arrays and Structs."
    examples: { '(get val key [key2…])' }

  value: class extends Op
    pattern = (val! / evt!) + (const.str / const.sym / const.num)*0
    setup: (inputs) =>
      { val, keys } = pattern\match inputs
      super val: Input.hot val

      @state = [key.result! for key in *keys]

      type = val\type!
      for key in *@state
        type = type\get key

      if val\metatype == '!'
        @out = type\mk_evt!
      else
        @out = type\mk_sig!

    tick: =>
      val = @inputs.val!
      for key in *@state
        if type(key) == 'number'
          key = key + 1
        val = val[key]
      @out\set val

Scope.from_table {
  :doc
  :trace, 'trace=': trace_, print: print_

  :def, :use
  require: require_
  import: import_
  'import*': import_star
  export: export_
  'export*': export_star

  '=': to_const
  '~': to_sig
  '!': to_evt

  :array, :struct, :get

  true: Constant.meta
    meta:
      name: 'true'
      summary: "The boolean constant `true`."
    value: Constant.bool true

  false: Constant.meta
    meta:
      name: 'false'
      summary: "The boolean constant `false`."
    value: Constant.bool false

  bang: Constant.meta
    meta:
      name: 'bang'
      summary: "A `bang` value-constant."
    value: Constant T.bang, true

  :fn, :defn
  'do': do_expr
  if: if_
}