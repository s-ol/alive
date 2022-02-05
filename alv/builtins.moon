----
-- Builtin `Builtin`s and `Op`s.
--
-- Please see the [reference](../../reference/index.html#builtins) for
-- documentation.
--
-- @module builtins
import Builtin, Op, PureOp, T, FnDef, Input, const, sig, evt, any, Struct, Array
  from require 'alv.base'
import Constant from require 'alv.result'
import Error from require 'alv.error'
import RTNode from require 'alv.rtnode'
import Cell from require 'alv.cell'
import Dummy from require 'alv.dummy'
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
      super with RTNode children: { def }
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

      super RTNode :children

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

      super RTNode!

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
      name = node\const!\unwrap T.str

      L\trace @, "loading module #{name}"
      super COPILOT\require name

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
      super RTNode :children

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
      super RTNode :children

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
      super RTNode :children, result: Constant.wrap new_scope

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

      super RTNode :children, result: Constant.wrap new_scope

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

      super RTNode result: with Constant.wrap FnDef param_symbols, body, scope
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
      super RTNode!

do_ = Constant.meta
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
      result = if last = children[#children] then last.result

      super RTNode :children, :result

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
      if not xif\is_const!
        msg = "'if'-expression needs to be constant, did you mean 'switch'?"
        error Error 'argument', msg
      xif = xif.result\unwrap!
      @state = xif != nil and xif != false and xif != 0

      super if @state
        xthen\eval scope
      elseif xelse
        xelse\eval scope
      else
        RTNode!

    vis: => step: if @state then 0 else 1

when_ = Constant.meta
  meta:
    name: 'when'
    summary: "Make an evaltime const choice with side effects"
    examples: { '(when bool then-exprs…)' }
    description: "
`bool` has to be an evaltime constant. If it is truthy, this expression is equivalent
to `(do then-exprs…)`, otherwise it results in nil."

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail >= 2, "'when' needs at least two parameters"

      xif = L\push tail[1]\eval, scope
      if not xif\is_const!
        msg = "'when'-expression needs to be constant, did you mean 'switch'?"
        error Error 'argument', msg
      xif = xif.result\unwrap!
      @state = xif != nil and xif != false and xif != 0

      super if @state
        scope = Scope scope
        children = [expr\eval scope for expr in *tail[2,]]
        result = if last = children[#children] then last.result
        if result and result.metatype == '='
          result = result.type\mk_sig result\unwrap!

        RTNode :children, :result
      else
        RTNode!

switch_ = Constant.meta
  meta:
    name: 'switch'
    summary: "Switch between multiple inputs."
    examples: { '(switch i v1 v2…)' }
    description: "
- When fed a bang! trigger, steps forward to the next step on each trigger.
- When fed a num~ or num! stream, reproduces the matching argument (indexed
  starting from 0).
- When fed a bool~ or bool! stream, outputs the first or second argument for
  `true` and `false` respectively. This version takes at most two argumetns."

  value: class extends Op
    pattern = (sig.num / sig.bool / evt.num / evt.bool / evt.bang) + any!!*0
    setup: (inputs) =>
      { i, values } = pattern\match inputs

      val1 = values[1]
      @setup_out val1.result.metatype, val1.result.type

      if i\type! == T.bang
        @state or= 1

      super
        i: Input.hot i
        values: [Input.hot v for v in *values]

    tick: =>
      { :i, :values } = @inputs

      if i\type! == T.bang
        if i\dirty!
          @state += 1
          @state = @state % (#values)
      else
        @state = switch i!
          when true then 0
          when false then 1
          else (math.floor i!) % #values

      @out\set if v = values[@state + 1] then v!

    vis: =>
      with Op.vis @
        .step = @state

trace_ = Constant.meta
  meta:
    name: 'trace='
    summary: "Trace an expression's value at evaltime."
    examples: { '(trace= expr)' }

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace!' takes exactly one parameter"

      super with node = L\push tail[1]\eval, scope
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

        @out = inputs[2].result

      tick: =>
        L\print "trace #{@inputs.prefix!}: #{@inputs.value.result}"

    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 1, "'trace' takes exactly one parameter"

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, {
        Dummy.literal T.opdef, traceOp
        Constant.str tail[1]\stringify 2
        tail[1]
      }
      super inner\eval scope

print_ = Constant.meta
  meta:
    name: 'print'
    summary: "Print string values."
    examples: { '(print str)' }

  value: class extends Op
    setup: (inputs) =>
      value = (sig.str / evt.str)\match inputs
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
      input = const!\match inputs
      super value: Input.hot input
      @out = input.result

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
      { event, initial } = any!\match inputs
      assert event\type! == initial\type!,
        Error 'argument', "~ arguments have to be of the same type"

      super event: Input.hot event

      @setup_out '~', event\type!, initial.result!

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
    pattern = (sig! + evt.bang) / any!\rep(1,1)
    setup: (inputs) =>
      { sig_, trig } = pattern\match inputs
      if trig
        super
          trig: Input.hot trig
          sig: Input.cold sig_
      elseif sig_\metatype! == '!'
        super
          trig: Input.hot sig_
          sig: Input.cold Constant.bang true
      else
        super sig: Input.hot sig_

      @setup_out '!', @inputs.sig\type!

    tick: (setup) =>
      return if setup
      @out\set @inputs.sig!

merge = Constant.meta
  meta:
    name: 'merge!'
    summary: "Merge !-streams."
    examples: { '(merge! evt1 evt2 [evt3…])' }
    description: "
Merges two or more !-streams of the same type.
Whenever any of the input events fires, the output fires the same value.

In case of collisions, the event that comes first in the argument list wins."

  value: class extends Op
    pattern = any!!\rep 2
    setup: (inputs) =>
      values = pattern\match inputs
      super [Input.hot v for v in *values]
      @setup_out '!', @inputs[1]\type!

    tick: =>
      for input in *@inputs
        if input\dirty!
          @out\set input!
          return

array = Constant.meta
  meta:
    name: 'array'
    summary: "Construct an array."
    examples: { '(array a b c…)' }
    description: "Produces an array of values.

`a`, `b`, `c`… have to be values of the same type.
This is a pure op, so at most one !-stream input is allowed."

  value: do
    class extends PureOp
      pattern: any!!*0
      type: (args) =>
        Array #args, args[1]\type!

      tick: =>
        args = @unwrap_all!
        @out\set args

struct = Constant.meta
  meta:
    name: 'struct'
    summary: "Construct an struct."
    examples: { '(struct key1 val1 [key2 val2…])' }
    description: "Produces a struct of values.

`key1`, `key2`, … have to be constant expressions.
This is a pure op, so at most one !-stream input is allowed."

  value: do
    key = const.str / const.sym
    pair = (key + any!)\named 'key', 'val'

    class extends PureOp
      pattern: pair*0
      type: (pairs) =>
        Struct {key.result!, val\type! for {:key, :val} in *pairs}

      tick: =>
        pairs = @unwrap_all!
        @out\set {key, val for {:key, :val} in *pairs}

loop = Constant.meta
  meta:
    name: 'loop'
    summary: "Loop on arbitrary data via recursion."
    examples: { '(loop (k1 v1 [k2 v2…]) body)' }
    description: "
Defines a recursive loop function `*recur*` with parameters `k1`, `k2`, … and
function body `body`, then invokes it immediately with arguments `v1`, `v2`, …

Inside the `body`, `(recur)` is used to recursively restart loop evaluation
with a different set of arguments, e.g. to sum the first `5` integers:

    (loop (n 5)
      (if (= n 0)
        0
        (+ n (recur (n - 1)))))"

  value: class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail == 2, "'loop' takes exactly two arguments"
      { binds, body } = tail

      assert binds.__class == Cell, "loops bindings have to be an cell"
      assert #binds.children % 2 == 0, "key without binding in loop binding"

      names = {}
      inner = { Constant.sym '*recur*' }
      for i=1,#binds.children,2
        table.insert names, binds.children[i]
        table.insert inner, binds.children[i+1]

      loop_fn = FnDef names, body, scope

      def_scope = Scope scope
      def_scope\set '*recur*', RTNode result: Constant.wrap loop_fn

      tag = @tag\clone Tag.parse '-1'
      inner = Cell tag, inner
      super inner\eval def_scope

recur = Constant.meta
  meta:
    name: 'recur'
    summary: "Reenter the innermost loop."
    examples: { '(recur nv1 [nv2…])' }
    description: "
Reenters the innermost `(loop)` from the top, with `k1` bound to `nv1`, `k2`
bound to `nv2`…

`(recur nv1 [nv2…])` is equivalent to `(*recur* nv1 [nv2…])`."

  value: class extends Builtin
    eval: (caller_scope, tail) =>
      L\trace "evaling #{@}"
      recur_fn = assert caller_scope\get '*recur*', "not currently in any loop"
      fndef = recur_fn.result\unwrap T.fndef, "*recur* has to be a fndef"

      { :params, :body } = fndef
      if #params != #tail
        err = Error 'argument', "expected #{#params} loop arguments, found #{#tail}"
        error err

      fn_scope = Scope fndef.scope, caller_scope

      children = for i=1,#params
        name = params[i]\unwrap T.sym
        with L\push tail[i]\eval, caller_scope
          fn_scope\set name, \make_ref!

      clone = body\clone @tag
      node = clone\eval fn_scope

      table.insert children, node
      super RTNode :children, result: node.result

mk_thread = (name, thread_first) ->
  class extends Builtin
    eval: (scope, tail) =>
      L\trace "evaling #{@}"
      assert #tail > 1, "'#{name}' requires at least 2 arguments"

      last_result = tail[1]

      for cell in *tail[2,]
        assert cell.__class == Cell, "'#{name}'s arguments have to be expressions"

        children = [c for c in *cell.children]
        if thread_first
          table.insert children, 2, last_result
        else
          table.insert children, last_result

        last_result = Cell cell.tag, children

      super last_result\eval scope, tail

thread_first = Constant.meta
  meta:
    name: '->'
    summary: "Thread first macro."
    examples: { '(-> initial [expr1 expr2…])' }
    description: "
Evaluate expressions `expr1`, `expr2`, … while passing the result of the
previous expression to the following one, starting with `initial`. The value
is always inserted as the first argument."

  value: mk_thread '->', true

thread_last = Constant.meta
  meta:
    name: '->>'
    summary: "Thread last macro."
    examples: { '(->> initial [expr1 expr2…])' }
    description: "
Evaluate expressions `expr1`, `expr2`, … while passing the result of the
previous expression to the following one, starting with `initial`. The value
is always inserted as the last argument."

  value: mk_thread '->>', false

Constant.meta
  meta:
    summary: "builtin operators and constants."

  value:
    :doc
    :trace, 'trace=': trace_, print: print_

    :def, :use
    require: require_
    import: import_
    'import*': import_star
    export: export_
    'export*': export_star

    :fn, :defn
    'do': do_
    'if': if_
    'when': when_
    'switch': switch_

    '=': to_const
    '~': to_sig
    '!': to_evt
    'merge!': merge

    '->': thread_first
    '->>': thread_last

    :array, :struct

    :loop, :recur

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
