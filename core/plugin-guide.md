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
`Scope.from_table`. All exports should be documented using `ValueStream.meta`,
which attaches a `meta` table to the value that is used for error messages,
documentation generation and [`(doc)`][builtins-doc].

    import ValueStream from require 'core.base'
    
    two = ValueStream.meta
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

    import ValueStream, Op, Input, match from require 'core.base'

    total_sum = ValueStream.meta
      meta:
        name: 'total-sum'
        summary: "Keep a total of incoming numbers."
        examples: { '(total-sum num!)' }
        description: "Keep a total sum of incoming number events, plugin-style."

      value: class extends Op
        new: (...) =>
          super ...
          @state or= { total: 0 }
          @out or= ValueStream 'num', @state.total
                
        setup: (inputs, scope) =>
          { num } = match 'num!', inputs
          
          super num: Inputs.hot num
        
        tick: =>
          @state.total += @inputs.num!
          @out\set @state.total
    {
      'total-sum': total_sum
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
is the type-name of an argument. Parts can be optional (`num?`), multiple
(`*num` - one or more numbers) or both (`*num?` - zero or more numbers). If
there is an equals sign in front of a part, the corresponding `Result` has to be
*evaltime constant*. The special typename `any` can be used for generic Ops.

If there are more complex dependencies between arguments, it is recommended to
do as much of the parsing as possible using `match`, and then continue
manually. For invalid or missing arguments, `Error` instances should be thrown
using `error` or `assert`.

#### input setup
There are two types of inputs: `Input.hot` and `Input.cold`:

*Cold* inputs do not cause the Op to update when changes to the input stream
are made. They are useful to 'ignore' changes to inputs which are only relevant
when another input changed value. Imagine for example a `send-value-when` Op,
which sends a value only when a `bang!` input is live. This Op doesn't have to
update when the value changes, it's enough to update only when the trigger input
changes and simply read the value in that moment.

*Hot* inputs on the other hand mark the input stream as a dependency for the
Op. Depending on the type of `Stream`, the semantics are a little different:

- For `ValueStream`s, the Op updates whenever the current value changes. When
  an input stream is swapped out for another one at evaltime, but their values
  are momentarily equal, the input is not considered dirty.
- For `EventStream`s and `IOStream`s, the Op updates whenever the stream is
  dirty. There is no special handling when the stream is swapped out at
  evaltime.

All `Result`s from the `inputs` argument that are taken into consideration
should be wrapped in an `Input` instance using either `Input.hot` or
`Input.cold`, and need to be passed to the `Op:setup` super implementation.
To illustrate with the `send-value-when` example:

    setup: (inputs, scope) =>
      { trig, value } = match 'bang! any', inputs
      
      super
        trig: Inputs.hot trig
        value: Inputs.cold value

`Op:setup` takes a table that can have any (even nested) shape you want, as
long as all 'leaf values' are `Input` instances. The following are both valid:
        
    super { (Inputs.hot trig), (Inputs.cold value) }
    
    super
      trigger:Inputs.hot trig
      values: { (Inputs.cold val0), (Inputs.cold val1), (Inputs.cold val2) }

#### output setup
When `Op:setup` finishes, `@out` has to be set to a `Stream` instance. The
instance can be created in `Op:setup`, or by overriding the constructor and
delegating to the original one using `super`. In general setting it in the
constructor is preferred, and it is only moved to `Op:setup` if the output
type depends on the arguments received.

There are three types of `Stream`s that can be created:

- `ValueStream`s track *continuous values*. They can only have one value per
  tick, and downstream Ops will not update when a *ValueStream* has been set
  to the same value it already had. They are updated using `ValueStream:set`.
- `EventStream`s transmit *momentary events*. They can transmit multiple events
  in a single tick. `EventStream`s do not keep a value set on the last tick on
  the next tick. They are updated using `EventStream:add`.
- `IOStream`s are like `EventStream`s, but their `IOStream:tick` method is
  polled by the event loop at the start of every tick. This gives them a chance
  to effectively create changes 'out of thin air' and kickstart the execution
  of the dataflow engine. All *runtime* execution is due to an `IOStream`
  becoming dirty somewhere.

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

[lua]:          https://www.lua.org/
[moonscript]:   http://moonscript.org/
[builtins-doc]: ../../reference/index.html#doc
