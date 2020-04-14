----
-- Builtin `Builtin`s and `Op`s.
--
-- Please see the [reference](../../reference/index.html#builtins) for
-- documentation.
--
-- @module builtin
import Builtin, Op, FnDef, Input, val, evt from require 'alv.base'
import ValueStream, LiteralValue from require 'alv.stream.value'
import Result from require 'alv.result'
import Cell from require 'alv.cell'
import Scope from require 'alv.scope'
import Tag from require 'alv.tag'
import op_invoke from require 'alv.invoke'

doc = ValueStream.meta
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

      result = L\push tail[1]\eval, scope
      with Result children: { def }
        meta = result.value.meta
        L\print "(doc #{tail[1]}):\n#{format_meta meta}\n"

def = ValueStream.meta
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
          name = (name\quote scope)\unwrap 'sym'

          with val_expr\eval scope
            scope\set name, \make_ref!

      Result :children

use = ValueStream.meta
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
        result = L\push child\eval, scope
        value = result\const!
        scope\use value\unwrap 'scope', "'use' only works on scopes"

      Result!

require_ = ValueStream.meta
  meta:
    name: 'require'
    summary: "Load a module."
    examples: { '(require name)' }
    description: "Load a module and return its scope."

  value: class extends Builtin
    eval: (scope,  tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'require' takes exactly one parameter"

      result = L\push tail[1]\eval, scope
      name = result\const!

      L\trace @, "loading module #{name}"
      scope = ValueStream.wrap require "alv-lib.#{name\unwrap 'str'}"
      Result :value

import_ = ValueStream.meta
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

      for child in *tail
        name = (child\quote scope)\unwrap 'sym'
        value = ValueStream.wrap require "alv-lib.#{name}"
        scope\set name, Result :value
      Result!

import_star = ValueStream.meta
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


      for child in *tail
        name = (child\quote scope)\unwrap 'sym'
        value = ValueStream.wrap require "alv-lib.#{name}"
        scope\use value\unwrap 'scope'

      Result!

fn = ValueStream.meta
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
        assert param.type == 'sym', "function parameter declaration has to be a symbol"
        param\quote scope

      body = body\quote scope
      Result value: with ValueStream.wrap FnDef param_symbols, body, scope
        .meta = {
          summary: "(user defined function)"
          examples: { "(??? #{table.concat [p! for p in *param_symbols], ' '})" }
        }

defn = ValueStream.meta
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

      name = (name\quote scope)\unwrap 'sym'
      assert params.__class == Cell, "'defn's second argument has to be an expression"
      param_symbols = for param in *params.children
        assert param.type == 'sym', "function parameter declaration has to be a symbol"
        param\quote scope

      body = body\quote scope

      value = with ValueStream.wrap FnDef param_symbols, body, scope
        .meta =
          :name
          summary: "(user defined function)"
          examples: { "(#{name} #{table.concat [p! for p in *param_symbols], ' '})" }

      scope\set name, Result :value
      Result!

do_expr = ValueStream.meta
  meta:
    name: 'do_expr'
    summary: "Evaluate multiple expressions in a new scope."
    examples: { '(do expr1 [expr2…])' }
    description: "
Evaluate `expr1`, `expr2`, … and return the value of the last expression."

  value: class  extends Builtin
    eval: (scope, tail) =>
      scope = Scope scope
      Result children: [expr\eval scope for expr in *tail]

if_ = ValueStream.meta
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

trace_ = ValueStream.meta
  meta:
    name: 'trace!'
    summary: "Trace an expression's value at evaltime."
    examples: { '(trace! expr)' }

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      with result = L\push tail[1]\eval, scope
        L\print "trace! #{tail[1]\stringify!}: #{result.value}"

trace = ValueStream.meta
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
        L\print "trace #{@inputs.prefix!}: #{@inputs.value.stream}"

    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, {
        LiteralValue 'opdef', traceOp, 'trace'
        ValueStream.str tostring tail[1]
        tail[1]
      }
      inner\eval scope

print = ValueStream.meta
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
          print msg
      else
        print @inputs.value!

{
  :doc
  :trace, 'trace!': trace_, :print

  :def, :use
  require: require_
  import: import_
  'import*': import_star

  true: ValueStream.meta
    meta:
      name: 'true'
      summary: "The boolean constant `true`."
    value: ValueStream.bool true

  false: ValueStream.meta
    meta:
      name: 'false'
      summary: "The boolean constant `false`."
    value: ValueStream.bool false

  bang: ValueStream.meta
    meta:
      name: 'bang'
      summary: "A `bang` value-constant."
    value: ValueStream 'bang', true

  :fn, :defn
  'do': do_expr
  if: if_
}
