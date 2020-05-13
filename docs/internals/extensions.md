# writing `alv` extensions

Extensions for `alv` are implemented in [Lua][lua] or [MoonScript][moonscript]
(which runs as Lua). When an `alv` module is [`(require)`][builtins-req]d,
alv looks for a Lua module `alv-lib.[module]`. You can simply add a new file
with extension `.lua` or `.moon` in the `alv-lib` directory of your alv
installation or somewhere else in your `LUA_PATH`.

To write extensions, a number of classes and utilities are required. All of
these are exported in the `base` module.

## documentation metadata
The lua module should return a `Scope` or a table that will be converted using
`Scope.from_table`. All exports should be documented using `Constant.meta`,
which attaches a `meta` table to the value that is used for error messages,
documentation generation and [`(doc)`][builtins-doc].

    import Constant from require 'alv.base'

    two = Constant.meta
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
Most extensions will want to define a number of *Op*s to be used by the user.
They are implemented by deriving from the `Op` class and implementing at least
the `Op:setup` and `Op:tick` methods.

    import Constant, SigStream, Op, Input, evt from require 'alv.base'

    total_sum = Constant.meta
      meta:
        name: 'total-sum'
        summary: "Keep a total of incoming numbers."
        examples: { '(total-sum num!)' }
        description: "Keep a total sum of incoming number events, extension-style."

      value: class extends Op
        new: (...) =>
          super ...
          @state or= { total: 0 }
          @out or= SigStream 'num', @state.total

        setup: (inputs, scope) =>
          num = evt.num\match inputs
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
Arguments should be parsed using `base.match`. The two exports `base.match.val`
and `base.match.evt` are used to build complex patterns that can parse and
validate the Op arguments into complex structures (see the module documentation
for more information).

    import val, evt from require 'alv.base'

    pattern = evt.bang + val.str + val.num*3 + -evt!
    { trig, str, numbers, optional } = pattern\match inputs

This example matches first an `EvtStream` of type `bang`, then a `SigStream`
of type `str`, followed by one, two or three `num`-values and finally an
optional argument `EvtStream` of any type. `:match` will throw an error if it
couldn't (fully) match the arguments and otherwise return a structured mapping
of the inputs.

If there are more complex dependencies between arguments, it is recommended to
do as much of the parsing as possible using the `base.match` and then continue
manually. For invalid or missing arguments, `Error` instances should be thrown
using `error` or `assert`.

#### input setup
There are two types of inputs: `Input.hot` and `Input.cold`:

*Cold* inputs do not cause the Op to update when changes to the input stream
are made. They are useful to 'ignore' changes to inputs which are only relevant
when another input changed value. Imagine for example a `send-value-when` Op,
which sends a value only when a `bang!` input is live. This Op doesn't have to
update when the value changes, it's enough to update only when the trigger
input changes and simply read the value in that moment.

*Hot* inputs on the other hand mark the input stream as a dependency for the
Op. Depending on the type of `Result`, the semantics are a little different:

- For `SigStream`s, the Op updates whenever the current value changes. When
  an input stream is swapped out for another one at evaltime, but their values
  are momentarily equal, the input is not considered dirty.
- For `EvtStream`s and `IOStream`s, the Op updates whenever the stream is
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
      trigger: Inputs.hot trig
      values: { (Inputs.cold a), (Inputs.cold b), (Inputs.cold c) }

#### output setup
When `Op:setup` finishes, `@out` has to be set to a `Result` instance. The
instance can be created in `Op:setup`, or by overriding the constructor and
delegating to the original one using `super`. In general setting it in the
constructor is preferred, and it is only moved to `Op:setup` if the output
type depends on the arguments received.

There are four types of `Result`s that can be created:

- `SigStream`s track *continuous values*. They can only have one value per
  tick, and downstream Ops will not update when a *SigStream* has been set
  to the same value it already had. They are updated using `SigStream:set`.
- `EvtStream`s transmit *momentary events*. They can transmit multiple events
  in a single tick. `EvtStream`s do not keep a value set on the last tick on
  the next tick. They are updated using `EvtStream:set`.
- `IOStream`s are like `EvtStream`s, but their `IOStream:poll` method is
  polled by the event loop at the start of every tick. This gives them a chance
  to effectively create changes 'out of thin air' and kickstart the execution
  of the dataflow engine. All *runtime* execution is due to an `IOStream`
  becoming dirty somewhere. See the section on implementing `IOStream`s below
  for more information.
- `Constant`s do not change in-between evalcycles. Usually Ops do not output
  `Constant`s directly, althrough `SigStream`s outputs are automatically
  'downgraded' to `Constant`s when the Op has no reactive inputs.

### Op:tick
`Op:tick` is called whenever any of the inputs are *dirty*. This is where the
Op's main logic will go. Generally here it should be checked which input(s)
changed, and then internal state and the output value may be updated.

## defining `Builtin`s
Builtins are more powerful than Ops, because they control whether, which and
how their arguments are evaluated. They roughly correspond to *macros* in Lisps.
There is less of a concrete guideline for implementing Builtins because there
are a lot more options, and it really depends a lot on what the Builtin should
achieve. Nevertheless, a good starting point is to read the `Builtin` class
documentation, take a look at `Builtin`s in `alv/builtin.moon` and get
familiar with the relevant internal interfaces (especially `AST`, `Result`, and
`Scope`).

## defining `IOStream`s
`IOStream`s are `EvtStream`s that can 'magically' create events out of
nothing. They are the source of all processing in alv. Whenever you want to
bring events into alv from an external protocol or application, an IOStream
will be necessary.

To implement a custom IOStream, create it as a class that inherits from the
`IOStream` base and implement the constructor and `IOStream:poll`:

    import T, IOStream from require 'alv.base'
    
    class UnreliableStream extends IOStream
      new: => super T.bang
      
      poll: =>
        if math.random! < 0.1
          @set true

In the constructor, you should call the super-constructor `EvtStream.new` to
set the event type. Often this will be a custom event that is only used inside
your extension (such as e.g. the `midi/port` type in the [midi][modules-midi]
module), but it can also be a primitive type like `T.bang` in this example. In
`:poll`, your IOStream is given a chance to communicate with the external world
and create any resulting events. The example stream above randomly sends bang
events out, with a 10% chance each 'tick' of the system. Note that there is no
guarantee about when or how often ticks occur, so you really shouldn't rely on
them this way in a real extension.

### using `IOStream`s
There's a couple of ways IOStreams can be used and exposed to the user of your
extension. You can either expose an instance of your IOStream directly
(documented using `SigStream.meta`), or offer an Op that creates and returns
an instance in `Op.out` - that way the IOStream can be created only on demand
and take parameters. It is also possible to not exepose the IOStream at all,
and rather pass it as a hardcoded input into an Op's `Op.inputs`.

[lua]:          https://www.lua.org/
[moonscript]:   http://moonscript.org/
[builtins-req]: ../../reference/index.html#require
[builtins-doc]: ../../reference/index.html#doc
[modules-midi]: ../../reference/midi.html
