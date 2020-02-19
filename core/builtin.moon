-- builtin special forms
import Action, FnDef from require 'core.base'
import Result, Value from require 'core.value'
import Cell from require 'core.cell'
import Scope from require 'core.scope'

class doc extends Action
  @doc: "(doc sym) - print documentation in console

prints the docstring for sym in the console"

  eval: (scope, tail) =>
    assert #tail == 1, "'doc' takes exactly one parameter"

    def = L\push tail[1]\eval, scope
    with Result children: { def }
      def = def.value\const!\unwrap!
      L\print "(doc #{tail[1]\stringify!}):\n#{def.doc}\n"

class def extends Action
  @doc: "(def sym1 val-expr1
    [sym2 val-expr2]...) - declare symbols in parent scope

defines the symbols sym1, sym2, ... to resolve to the values of val-expr1, val-expr2, ...
updates all val-exprs."

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

class use extends Action
  @doc: "(use scope1 [scope2]...) - merge scopes into parent scope

adds all symbols from scope1, scope2, ... to the parent scope.
all scopes have to be eval-time constants."

  eval: (scope, tail) =>
    L\trace "evaling #{@}"
    for child in *tail
      result = L\push child\eval, scope
      value = result\const!
      scope\use value\unwrap 'scope', "'use' only works on scopes"

    Result!

class require_ extends Action
  @doc: "(require name-str) - require a module

returns the module's scope
name-str has to be an eval-time constant."

  eval: (scope,  tail) =>
    L\trace "evaling #{@}"
    assert #tail == 1, "'require' takes exactly one parameter"

    result = L\push tail[1]\eval, scope
    name = result\const!

    L\trace @, "loading module #{name}"
    Result value: Value.wrap require "lib.#{name\unwrap 'str'}"

class import_ extends Action
  @doc: "(import sym1 [sym2]...) - require and define modules

requires modules sym1, sym2, ... and defines them as sym1, sym2, ... in the current scope"

  eval: (scope, tail) =>
    L\trace "evaling #{@}"
    assert #tail > 0, "'import' requires at least one arguments"

    for child in *tail
      name = (child\quote scope)\unwrap 'sym'
      scope\set name, Result value: Value.wrap require "lib.#{name}"

    Result!

class import_star extends Action
  @doc: "(import* sym1 [sym2]...) - require and use modules

requires modules sym1, sym2, ... and merges them into the current scope"

  eval: (scope, tail) =>
    L\trace "evaling #{@}"
    assert #tail > 0, "'import' requires at least one arguments"


    for child in *tail
      name = (child\quote scope)\unwrap 'sym'
      scope\use (Value.wrap require "lib.#{name}")\unwrap 'scope'

    Result!

class fn extends Action
  @doc: "(fn (p1 [p2]...) body-expr) - declare a (lambda) function

the symbols p1, p2, ... will resolve to the arguments passed to the function."

  eval: (scope, tail) =>
    L\trace "evaling #{@}"
    assert #tail == 2, "'fn' takes exactly two arguments"
    { params, body } = tail

    assert params.__class == Cell, "'fn's first argument has to be an expression"
    param_symbols = for param in *params.children
      assert param.type == 'sym', "function parameter declaration has to be a symbol"
      param\quote scope

    body = body\quote scope
    Result value: Value.wrap FnDef param_symbols, body, scope

class defn extends Action
  @doc: "(defn name-sym (p1 [p2]...) body-expr) - define a function

declares a lambda (see (doc fn)) and defines it in the current scope"

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
    fn = FnDef param_symbols, body, scope

    scope\set name, Result value: Value.wrap fn
    Result!

class do_expr extends Action
  @doc: "(do expr1 [expr2]...) - update multiple expressions

evaluates and continously updates expr1, expr2, ...
the last expression's value is returned."

  eval: (scope, tail) =>
    Result children: [expr\eval scope for expr in *tail]

class if_ extends Action
  @doc: "(if bool then-expr [else-xpr]) - make an eval-time const choice

bool has to be an eval-time constant. If it is truthy, this expression is equivalent
to then-expr, otherwise it is equivalent to else-xpr if given, or nil otherwise."

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

class trace extends Action
  @doc: "(trace expr) - print an eval-time constant to the console"

  eval: (scope, tail) =>
    L\trace "evaling #{@}"
    assert #tail == 1, "'trace' takes exactly one parameter"

    with result = L\push tail[1]\eval, scope
      L\print "trace #{tail[1]\stringify!}: #{result.value}"

{
  :doc, :trace

  :def, :use
  require: require_
  import: import_
  'import*': import_star

  true: Value.bool true
  false: Value.bool false

  :fn, :defn
  'do': do_expr
  if: if_
}
