# writing `alive` plugins

Plugins for `alive` are implemented in [Lua][lua] or [MoonScript][moonscript]
(which runs as Lua). When an `alive` module is [require][]d, alive looks for a
Lua module `lib.[module]`. You can simply add a new file with extension `.lua`
or `.moon` in the `lib` directory of your alive installation or somewhere else
in your `LUA_PATH`.

To write plugins, a number of classes and utilities are required. All of these
are exported in the `base` module.

## documentation metadata
The lua module should return a `Scope` or a table that will be converted using
`Scope.from_table`. All exports should be documented using `Value.meta`, which
attaches a `meta` table to the value that is used for error messages,
documentation generation and [`(doc)`][builtins-doc].

    import Value from require 'core.base'
    
    two = Value.meta
      meta:
        name: 'two'
        summary: "the number two"
      value: 2
    
    {
      :two
    }

In the `meta` table `summary` is the only required key, but all of the
information that applies should be provided.

- `name`: the name of this export (for error reporting).
- `summary`: a one-line plain-text description of this entry. Should be
  capitalized and end with a period.
- `examples`: a table of strings, each of which is a short one-line code
  example illustrating the argument names for an Op.
- `description`: a longer markdown-formatted description of the functionality
  of this entry.

## defining `Op`s
Most plugins will want to define a number of *Op*s to be used by the user. They
are implemented by deriving from the `Op` class and implementing at least the
`Op:setup` and `Op:tick` methods.

    import Value, Op, Input, match from require 'core.base'

    my_add = Value.meta
      meta:
        name: 'my-add'
        summary: "Add two numbers."
        examples: { '(my-add a b)' }
        description: "Add two numbers, plugin-style."

      value: class extends Op
        new: => super 'num'
        
        setup: (inputs, scope) =>
          { a, b } = match 'num num', inputs
          
          super
            a: Inputs.value a
            b: Inputs.value b
        
        tick: =>
          @out\set @inputs.a! + @inputs.b!

    {
      'my-add': my_add
    }

### Op:setup
`Op:setup` is called once every *eval cycle* to parse the Op's arguments, check
their types, choose the updating behaviour and define the output type.

The arguments to `:setup` are a list of inputs (each is a `Result` instance),
and the `Scope` the evaluation happened in. Ops generally shouldn't use the
scope, but might look up 'magic' dynamic symbols like `\*clock\*`.

#### argument parsing
Arguments should be parsed using `match`. It takes a string that describes the
argument types and matches them against the provided arguments:
    
    import match from require 'core.base'

    { str, numbers, optional } = match 'str *num any?', inputs

`match` matches arguments greedily from left to right. Each part of the string
is the type-name of a Value. Parts can be optional (`num?`), multiple (`*num` -
one or more numbers) or both (`*num?` - zero or more numbers). If there is an
equals sign in front of a part, the corresponding `Result` has to be
*evaltime constant*. The special typename `any` can be used for generic Ops.

If there are more complex dependencies between arguments, it is recommended to
do as much of the parsing as possible using `match`, and then continue
manually. For invalid or missing arguments, `Error` instances should be thrown
using `error` or `assert`.

#### input setup

(section wip since changes are anticipated)

#### output setup

When `Op:setup` finishes, `@out` has to be set to a `Value` instance. The
instance can be created in `Op:setup`, or by overriding the constructor and
delegating to the original one using `super`. In general this way of creating
the output value is preferred, and it is only moved to `Op:setup` if the output
type depends on the arguments received.

### Op:tick
`Op:tick` is called whenever any of the inputs are *dirty*. This is where the
Op's main logic will go. Generally here it should be checked which input(s)
changed, and then internal state and the output value may be updated.

## defining `Action`s
`Action`s are more powerful than `Op`s, because they control whether, which and
how their arguments are evaluated. They roughly correspond to *macros* in Lisps.
Since it is rarely necessary to implement `Action`s, there is currently no
documentation on implementing them, but the `Action` class documentation and the
examples in `core/builtin.moon` should be enough to get started.

## `IO`s

(wip)

[lua]:          https://www.lua.org/
[moonscript]:   http://moonscript.org/
[builtins-doc]: ../../reference/index.html#doc
