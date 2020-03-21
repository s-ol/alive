----
-- Builtin `Action`s and `Op`s.
--
-- Please see the [reference](../../reference/index.html#builtins) for
-- documentation.
--
-- @module builtin
import Action, Op, FnDef, Input, match from require 'core.base'
import Value, LiteralValue from require 'core.value'
import Result from require 'core.result'
import Cell from require 'core.cell'
import Scope from require 'core.scope'
import Tag from require 'core.tag'
import op_invoke from require 'core.invoke'

doc = Value.meta
  meta:
    name: 'doc'
    summary: "Print documentation in console."
    examples: { '(doc sym)' }
    description: "Print the documentation for `sym` to the console"

  value: class extends Action
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

def = Value.meta
  meta:
    name: 'def'
    summary: "Declare symbols in current scope."
    examples: { '(def sym1 val-expr1 [sym2 val-expr2…])' }
    description: "
Define the symbols `sym1`, `sym2`, … to resolve to the values of `val-expr1`,
`val-expr2`, …."

  value: class extends Action
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

use = Value.meta
  meta:
    name: 'use'
    summary: "Merge scopes into current scope."
    examples: { '(use scope1 [scope2…])' }
    description: "
Copy all symbol definitions from `scope1`, `scope2`, … to the current scope.
All arguments have to be evaltime constant."

  value: class extends Action
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      for child in *tail
        result = L\push child\eval, scope
        value = result\const!
        scope\use value\unwrap 'scope', "'use' only works on scopes"

      Result!

require_ = Value.meta
  meta:
    name: 'require'
    summary: "Load a module."
    examples: { '(require name)' }
    description: "Load a module and return its scope."

  value: class extends Action
    eval: (scope,  tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'require' takes exactly one parameter"

      result = L\push tail[1]\eval, scope
      name = result\const!

      L\trace @, "loading module #{name}"
      scope = Value.wrap require "lib.#{name\unwrap 'str'}"
      Result :value

import_ = Value.meta
  meta:
    name: 'import'
    summary: "Require and define modules."
    examples: { '(import sym1 [sym2…])' }
    description: "
Requires modules `sym1`, `sym2`, … and define them as `sym1`, `sym2`, … in the
current scope."

  value: class extends Action
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 0, "'import' requires at least one arguments"

      for child in *tail
        name = (child\quote scope)\unwrap 'sym'
        value = Value.wrap require "lib.#{name}"
        scope\set name, Result :value -- (require "lib.#{name})\unwrap 'scope'
      Result!

import_star = Value.meta
  meta:
    name: 'import*'
    summary: "Require and use modules."
    examples: { '(import* sym1 [sym2…])' }
    description: "
Requires modules `sym1`, `sym2`, … and merges them into the current scope."

  value: class extends Action
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 0, "'import' requires at least one arguments"


      for child in *tail
        name = (child\quote scope)\unwrap 'sym'
        value = Value.wrap require "lib.#{name}"
        scope\use value\unwrap 'scope' -- (require "lib.#{name}")\unwrap 'scope'

      Result!

fn = Value.meta
  meta:
    name: 'fn'
    summary: "Declare a function."
    examples: { '(fn (p1 [p2…]) body-expr)' }
    description: "
The symbols `p1`, `p2`, ... will resolve to the arguments passed when the
function is invoked."

  value: class extends Action
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 2, "'fn' takes exactly two arguments"
      { params, body } = tail

      assert params.__class == Cell, "'fn's first argument has to be an expression"
      param_symbols = for param in *params.children
        assert param.type == 'sym', "function parameter declaration has to be a symbol"
        param\quote scope

      body = body\quote scope
      Result value: with Value.wrap FnDef param_symbols, body, scope
        .meta = {
          summary: "(user defined function)"
          examples: { "(??? #{table.concat [p! for p in *param_symbols], ' '})" }
        }

defn = Value.meta
  meta:
    name: 'defn'
    summary: "Define a function."
    examples: { '(defn name-sym (p1 [p2…]) body-expr)' }
    description: "
Declare a function and define it as `name-sym` in the current scope.
The symbols `p1`, `p2`, ... will resolve to the arguments passed when the
function is invoked."

  value: class extends Action
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

      value = with Value.wrap FnDef param_symbols, body, scope
        .meta =
          :name
          summary: "(user defined function)"
          examples: { "(#{name} #{table.concat [p! for p in *param_symbols], ' '})" }

      scope\set name, Result :value
      Result!

do_expr = Value.meta
  meta:
    name: 'do_expr'
    summary: "Evaluate multiple expressions in a new scope."
    examples: { '(do expr1 [expr2…])' }
    description: "
Evaluate `expr1`, `expr2`, … and return the value of the last expression."

  value: class  extends Action
    eval: (scope, tail) =>
      scope = Scope scope
      Result children: [expr\eval scope for expr in *tail]

if_ = Value.meta
  meta:
    name: 'if'
    summary: "Make an evaltime const choice."
    examples: { '(if bool then-expr [else-expr])' }
    description: "
`bool` has to be an evaltime constant. If it is truthy, this expression is equivalent
to `then-expr`, otherwise it is equivalent to `else-xpr` if given, or nil otherwise."

  value: class extends Action
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

trace_ = Value.meta
  meta:
    name: 'trace!'
    summary: "Trace an expression's value at evaltime."
    examples: { '(trace! expr)' }

  value: class extends Action
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      with result = L\push tail[1]\eval, scope
        L\print "trace! #{tail[1]\stringify!}: #{result.value}"

trace = Value.meta
  meta:
    name: 'trace'
    summary: "Trace an expression's values at runtime."
    examples: { '(trace expr)' }

  value: class extends Action
    class traceOp extends Op
      setup: (inputs) =>
        { prefix, value } = match 'str any', inputs
        super
          prefix: Input.cold prefix
          value: Input.value value

      tick: =>
        L\print "trace #{@inputs.prefix!}: #{@inputs.value.stream}"

    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, {
        LiteralValue 'opdef', traceOp, 'trace'
        Value.str tostring tail[1]
        tail[1]
      }
      inner\eval scope

{
  :doc
  :trace, 'trace!': trace_

  :def, :use
  require: require_
  import: import_
  'import*': import_star

  true: Value.meta
    meta:
      name: 'true'
      summary: "The boolean constant `true`."
    value: Value.bool true

  false: Value.meta
    meta:
      name: 'false'
      summary: "The boolean constant `false`."
    value: Value.bool false

  :fn, :defn
  'do': do_expr
  if: if_
}
