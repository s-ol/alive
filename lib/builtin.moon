import Const, Cell, Action, FnDef, Scope from require 'core'

class UpdateChildren
  new: (@children) =>

  update: (dt) =>
    for child in *@children
      L\trace "updating #{child}"
      L\push child\update, dt

  get: => @children[#@children]\get!
  getc: => @children[#@children]\getc!

  __tostring: => '<forwarder>'

class doc extends Action
  @doc: "(doc sym) - print documentation in console

prints the docstring for sym in the console"

  eval: (scope, tail) =>
    assert #tail == 1, "'doc' takes exactly one parameter"

    def = L\push tail[1]\eval, scope, @registry
    L\print "(doc #{tail[1]\stringify!}):\n#{def\getc!.doc}\n"
    nil

class def extends Action
  @doc: "(def sym1 val-expr1
    [sym2 val-expr2]...) - declare symbols in parent scope

defines the symbols sym1, sym2, ... to resolve to the values of val-expr1, val-expr2, ...
updates all val-exprs."

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail > 1, "'def' requires at least 2 arguments"
    assert #tail % 2 == 0, "'def' requires an even number of arguments"

    values = L\push ->
      return for i=1,#tail,2
        name, val_expr = tail[i], tail[i+1]
        name = (name\quote scope, @registry)\getc 'sym'

        val = val_expr\eval scope, @registry
        scope\set name, Const.wrap_ref val
        val

    UpdateChildren values

class use extends Action
  @doc: "(use scope1 [scope2]...) - merge scopes into parent scope

adds all symbols from scope1, scope2, ... to the parent scope.
all scopes have to be eval-time constants."

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    for child in *tail
      value = L\push child\eval, scope, @registry
      L\trace @, "merging #{value} into #{scope}"
      assert value.type == 'scope', "'use' only works on scopes"
      scope\use value\getc 'scope'

    nil

class require_ extends Action
  @doc: "(require name-str) - require a module

returns the module's scope
name-str has to be an eval-time constant."

  eval: (scope,  tail) =>
    L\trace "expanding #{@}"
    assert #tail == 1, "'require' takes exactly one parameter"

    name = L\push tail[1]\eval, scope, @registry

    L\trace @, "loading module #{name}"
    Const.wrap require "lib.#{name\getc 'str'}"

class import_ extends Action
  @doc: "(import sym1 [sym2]...) - require and define modules

requires modules sym1, sym2, ... and defines them as sym1, sym2, ... in the current scope"

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail > 0, "'import' requires at least one arguments"


    for child in *tail
      name = (child\quote scope, @registry)\getc 'sym'
      scope\set name, Const.wrap require "lib.#{name}"

    nil

class import_star extends Action
  @doc: "(import* sym1 [sym2]...) - require and use modules

requires modules sym1, sym2, ... and merges them into the current scope"

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail > 0, "'import' requires at least one arguments"


    for child in *tail
      name = (child\quote scope, @registry)\getc 'sym'
      scope\use (Const.wrap require "lib.#{name}")\getc 'scope'

    nil

class fn extends Action
  @doc: "(fn (p1 [p2]...) body-expr) - declare a (lambda) function

the symbols p1, p2, ... will resolve to the arguments passed to the function."

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail == 2, "'fn' takes exactly two arguments"
    { params, body } = tail

    assert params.__class == Cell, "'fn's first argument has to be an expression"
    param_symbols = for param in *params.children
      assert param.type == 'sym', "function parameter declaration has to be a symbol"
      param\quote scope, @registry

    body = body\quote scope, @registry
    Const.wrap FnDef param_symbols, body, scope

class defn extends Action
  @doc: "(defn name-sym (p1 [p2]...) body-expr) - define a function

declares a lambda (see (doc fn)) and defines it in the current scope"

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail == 3, "'defn' takes exactly three arguments"
    { name, params, body } = tail

    name = (name\quote scope, @registry)\getc 'sym'
    assert params.__class == Cell, "'defn's second argument has to be an expression"
    param_symbols = for param in *params.children
      assert param.type == 'sym', "function parameter declaration has to be a symbol"
      param\quote scope, @registry

    body = body\quote scope, @registry
    fn = FnDef param_symbols, body, scope

    scope\set name, Const.wrap fn

    nil

class do_expr extends Action
  @doc: "(do expr1 [expr2]...) - update multiple expressions

evaluates and continously updates expr1, expr2, ...
the last expression's value is returned."

  eval: (scope, tail) =>
    UpdateChildren [(expr\eval scope, @registry) or Const.empty! for expr in *tail]

class if_ extends Action
  @doc: "(if bool then-expr [else-xpr]) - make an eval-time const choice

bool has to be an eval-time constant. If it is truthy, this expression is equivalent
to then-expr, otherwise it is equivalent to else-xpr if given, or nil otherwise."

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail >= 2, "'if' needs at least two parameters"
    assert #tail <= 3, "'if' needs at most three parameters"

    { xif, xthen, xelse } = tail

    xif = L\push xif\eval, scope, @registry
    xif = xif\getc!

    if xif
      xthen\eval scope, @registry
    elseif xelse
      xelse\eval scope, @registry

class trace extends Action
  @doc: "(trace expr) - print an eval-time constant to the console"

  eval: (scope, tail) =>
    L\trace "expanding #{@}"
    assert #tail == 1, "'trace' takes exactly one parameter"

    with val = L\push tail[1]\eval, scope, @registry
      L\print "trace:", val

{
  :doc, :trace

  :def, :use
  require: require_
  import: import_
  'import*': import_star

  true: Const.bool true
  false: Const.bool false

  :fn, :defn
  'do': do_expr
  if: if_
}
