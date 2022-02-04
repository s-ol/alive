# writing `alv` extensions

Extensions for `alv` are implemented in [Lua][lua] or [MoonScript][moonscript]
(which runs as Lua). When an `alv` module is [`(require)`][builtins-req]d,
alv looks for a Lua module `alv-lib.[module]`. You can simply add a new file
with extension `.lua` or `.moon` in the `alv-lib` directory of your alv
installation or somewhere else in your `LUA_PATH`.

To write extensions, a number of classes and utilities are required. All of
these are exported in the `base` module.

## alv values
In the alv runtime, values are represented as instances of one of the three
classes implementing the `Result` interface; `Constant`, `SigStream` or
`EvtStream`.

A `Result` contains a type, the "unwrapped" Lua value, and optional metadata.

### types
Different types are represented as instances of the `type.Type` interface.
Such types can be @{type.Primitive|Primitive} types (which are opaque to alv
user code), @{type.Array|Array}s or @{type.Struct|Struct}s.

@{type.Primitive|Primitive} types are identified simply as a string.
A primitive type should have a well-defined Lua equivalent that implementations
can expect when unwrapping a corresponding alv value. Here is how the types
used by alv and the standard library map to Lua values:

- `num`: Lua `number`
- `str`: Lua `string`
- `sym`: Lua `string`
- `bool`: Lua `boolean`
- `bang`: always Lua `true`
- `scope`: `Scope` instance
- `fndef`: `FnDef` instance
- `opdef`: class inheriting from `Op` or `PureOp`
- `builtin`: class inheriting from `Builtin`

New primitive types can be created by extensions to represent values that should be
opaque to other extensions and alv code. To avoid namespace collisions, such
primitive types should be prefixed with the extension name and a slash.
For example, the `love` extension uses the type `love/shape` internally.

To obtain primitive type instances easily, the `type.T` "magic table" is
provided. Simply indexing in this table will produce a cached
@{type.Primitive|Primitive} instance:

    import T from require 'alv.base'

    number_type = T.num
    shape_type = T['love/shape']

@{type.Array|Array}s and @{type.Struct|Struct}s are composite types that
contain other types.

Arrays contain a fixed number of elements of a single type. For example,
this code defines a "vec3" type that consists of three numbers:

    import T, Array from require 'alv.base'
    vec3 = Array 3, T.num

Structs contain a set of labelled values that can each have a different type.
This code snippet defines a "person" type with two keys, "name" and "age".

    import T, Struct from require 'alv.base'
    person = Struct { name: T.str, age: T.num }

`Type` instances provide shorthand methods to create instances of the three
*kinds* of `Result`:

    word = T.str\mk_const "hello" -- value required 
    odd_number = T.num\mk_sig 7   -- initial value (can be provided later)
    emails = T["email/message"]\mk_evt!

### metadata and documentation
Using `Constant.meta`, documentation metadata can also be attached to values.
This metadata is used for error messages, documentation generation and the
[`(doc)`][builtins-doc] builtin.

In the `meta` table `summary` is the only required key, but all of the
information that applies should be provided.

- `name`: the name of this export (for error reporting).
- `summary`: a one-line plain-text description of this entry. Should be
  capitalized and end with a period.
- `examples`: a table of strings, each of which is a short one-line code
  example illustrating the argument names for an Op.
- `description`: a longer markdown-formatted description of the functionality
  of this entry.

## module format
The lua module should return a `Result` which will be returned as the result
from [`(require)`][builtins-require]. In almost all cases, the return value
should be a `Scope` containing individual `Result`s that can be imported
together using [`(import)`][builtins-imp] and [`(import*)`][builtins-im_].

`Constant.meta` calls `Constant.wrap`, which will automatically turn raw tables
into `Scope`s and label other Lua primitive types correctly. 

    import Constant from require 'alv.base'

    -- define some values
    one = Constant.meta
      meta:
        name: 'one'
        summary: "the number one"
      value: 1

    two = Constant.meta
      meta:
        name: 'two'
        summary: "the number two"
      value: 2

    -- define and return a Constant of type "scope"
    -- that contains our exports
    Constant.meta
      meta:
        name: 'numbers'
        summary: "a module containing common numbers."
      value: { :one, :two }

## defining `Op`s
Most extensions will want to define a number of *Op*s to be used by the user.
They are implemented by deriving from the `Op` class and implementing at least
the `Op:setup` and `Op:tick` methods.

    import Constant, Op, Input, T, evt from require 'alv.base'

    total_sum = Constant.meta
      meta:
        name: 'total-sum'
        summary: "Keep a total of incoming numbers."
        examples: { '(total-sum num!)' }
        description: "Keep a total sum of incoming number events, extension-style."

      value: class extends Op
        setup: (inputs, scope) =>
          num = evt.num\match inputs

          super num: Inputs.hot num

          @state or= { total: 0 }
          @update_out '~', T.num, @state.total

        tick: =>
          @state.total += @inputs.num!
          @out\set @state.total

    Constant.meta
      meta:
        name: 'my-module'
        description: "This is my own awesome module."
      value: { 'total-sum': total_sum }

### Op:setup
`Op:setup` is called once every *eval cycle* to parse the Op's arguments, check
their types, choose the updating behaviour and define the output type.

The arguments to `:setup` are a list of inputs (each is a `Result` instance),
and the `Scope` the evaluation happened in. Ops generally shouldn't use the
scope, but might look up 'magic' dynamic symbols like `\*clock\*`.

#### argument parsing
Arguments should be parsed using `base.match`. `base.match.const`, `base.match.sig`
and `base.match.evt` are used to build complex patterns that can parse and
validate the Op arguments into complex structures (see the module documentation
for more information).

    import sig, evt from require 'alv.base'

    pattern = evt.bang + sig.str + sig.num*3 + -evt!
    { trig, str, numbers, optional } = pattern\match inputs

This example matches first an `EvtStream` of type `bang`, then a `SigStream`
of type `str`, followed by one, two or three `num`-values, and finally an
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

    pattern = evt.bang + sig!
    setup: (inputs, scope) =>
      { trig, value } = pattern\match inputs

      super
        trig: Inputs.hot trig
        value: Inputs.cold value

`Op:setup` takes a table that can have any (even nested) shape you want, as
long as all 'leaf values' are `Input` instances. The following are both valid:

    super { (Inputs.hot trig), (Inputs.cold value) }

    super
      trigger: Inputs.hot trig
      values: { (Inputs.cold a), (Inputs.cold b), (Inputs.cold c) }

#### state and output setup
When `Op:setup` finishes, `Op.out` has to be set to a `Result` instance. The
instance can be created in `Op:setup`, or in an overridden constructor.
The same is true for `Op.state`, which is an (optional) raw table of state
that the operator keeps. `Op.state` can be nested, but must only contain
"simple" types, so that it can be duplicated. For more complex behaviour,
`Op:fork` can be overridden (see below).

When overriding the constructor, it is important to delegate to the `Op`
constructor and pass on all arguments using `...`. Keep in mind that the
Constructor is called not only when an Op is first created, but also to
sandbox changes before potentially rolling them back (more on this below).

There are three types of `Result`s that can be created for `Op.out`:

- `SigStream`s track *continuous values*. They can only have one value per
  tick, and downstream Ops will not update when a *SigStream* has been set
  to the same value it already had. They are updated using `SigStream:set`.
- `EvtStream`s transmit *momentary events*. They can transmit multiple events
  in a single tick. `EvtStream`s do not keep a value set on the last tick on
  the next tick. They are updated using `EvtStream:set`.
- `Constant`s do not change in-between evalcycles. Usually Ops do not output
  `Constant`s directly, as `SigStream`s outputs are automatically
  'downgraded' to `Constant`s when the Op has no reactive inputs.

It is best to only recreate `Op.out` and `Op.state` if that is absolutely
necessary (e.g. the output type has changed as a result of new inputs).
This is so that the Op continues running smoothly without discontinuities when
unrelated changes are made.

For this reason, in most cases `Op.state` should be set up using
`@state or= ...`, and `Op.out` with `Op.setup_state`:

    setup: =>
      @state or= 0
      @setup_out '~', T.num, 2

Sometimes `Op.state` depends on the output type and needs to be reset when that
changes. When the output was recreated, `Op.setup_out` returns `true`.

### Op:tick
`Op:tick` is called whenever any of the inputs are *dirty*. This is where the
Op's main logic will go. Generally here it should be checked which input(s)
changed, and then internal state and the output value may be updated.

To check whether inputs are dirty, the `Input:dirty` method can be called.
Inputs can then be unwrapped using `Input:unwrap`, but they can also be called
directly as a shorthand:

    tick: =>
      value = @inputs.value
      @out\set value + 1

Since `Op:tick` is only called when there is a dirty input, it's often not
necessary to check which inputs are dirty.

For brevity, the helper method `Op:unwrap_all` can be used to unwrap all inputs.
It returns a table matching the shape of `Op.inputs`:

    setup: (inputs) =>
      trig, a, b, c = pattern\match inputs
      super
        trigger: Inputs.hot trig
        values: { (Inputs.cold a), (Inputs.cold b), (Inputs.cold c) }

    tick: =>
      { :values, :values } = @unwrap_all!

      @out\set trigger + values[1] + values[2] + values[3]

When an Op is newly created or a *hot* input changes during evaluation,
`Op:tick` is invoked at evaltime to update `Op.out`. In this case,
`Op:tick` receives `true` as an argument. This is useful in rare cases where
`Op.out` is an `EvtStream` that is set both in `Op:setup` and `Op:tick`, and
collisions must be prevented.

### Op:fork
When a running file is re-evaluated, all Ops are *forked* before re-running
`Op:setup` on them. This is important, so that if an error occurs at any point
in the evaluation process, the forked Ops can be discarded while the original
Ops keep running without being affected by any changes that may have occured
as a result (e.g. changes to `Op.out` or `Op.state`).

To obtain a mutable copy of an Op, `Op:fork` is called.
By default, this does the following:

- fork `Op.out` (if it exists) using `Result:fork`
- deep-copy `Op.state` (if it exists)
- construct a new `Op` by invoking the constructor with these two arguments

If necessary, `Op:fork` can be overridden with custom logic. This can be useful
when it is necessary to synchronize state with external systems.

### IO Ops (`Op:poll`)
Regular Ops only update in response to Input changes, but there is a need to
source events from outside the system to make anything happen at all.

This is accomplished by *IO Op*s. *IO Op*s are `Op` classes that define the
`Op:poll` method. Whenever the program is idle, all IO Ops will have this
method called at a high rate.

When the method is called, an IO Op should check any external conditions and
return `true` if it wishes to trigger a tick. In this case it should also
write to an internally-created `Result` instance to mark itself as "dirty":

    class extends Op
      setup: =>
        super io: Input.hot T.bang\mk_evt!

      poll: =>
        -- query external state here
        if something_changed
          @inputs.io.result\set true
          true

      tick: =>
        @out\set external_state

## PureOps
[*Pure Operators*][ref-04-2-pop] share common semantics for input *kinds*.
To implement them, the base class `PureOp` is provided and takes care of any
boilerplate (argument parsing, kind validation, output setup).

To implement a PureOp, you need to specify three parts:

1. the argument types `PureOp.pattern`
2. the output type `PureOp:type`
3. the tick logic `PureOp:tick`


The argument types are specified as a class member `PureOp.pattern` with a
pattern value from `base.match`. `Op.inputs` (and therefore `Op:unwrap_all`'s
result) will follow the shape of the match:

    class PowOp extends PureOp
      pattern: any.num + any.num
      type: T.num
      tick: => @out\set math.pow unpack @unwrap_all!


The output type can either by specified directly as a class member, or
implemented as a method that returns the type value. If `PureOp:type` is a
method, it will receive the Op inputs as parsed by `PureOp.pattern`:

    class MakeArrayOp extends PureOp
      pattern: any!*0
      type: (args) => Array #args, args[1]\type!
      tick: =>
        args = @unwrap_all!
        @out\set args

`Op:tick` is implemented just like for regular Ops. Because of the PureOp
semantics, there is no need to check which inputs are dirty, so it's
recommended to use `Op:unwrap_all` to access the inputs.

### overriding `PureOp:setup`
For more control, it is possible to override `PureOp:setup`. When calling
`super`, the first argument should be a table of results that are treated
according `PureOp.pattern` as usual. The second parameter should be
forwarded. In the third parameter, extra `Input`s can be specified that will
be merged into `Op.inputs`:

    class LogAll extends PureOp
      pattern: any.num*0

      full_pattern = -sig.str + any.num*0
      setup: (inputs, scope) =>
        { name, values } = full_pattern\match inputs
        super values, scope, {
          name: Input.cold name or scope\get '*name*'
        }

      tick: =>
        args = @unwrap_all!
        for i=1,#args
          print args.name, args[i]

## defining `Builtin`s
Builtins are more powerful than Ops because they control whether, how and
when their arguments are evaluated. They roughly correspond to *macros* in Lisps.
There is less of a concrete guideline for implementing Builtins because there
are a lot more options, and it really depends a lot on what the Builtin should
achieve. Nevertheless, a good starting point is to read the `Builtin` class
documentation, take a look at `Builtin`s in `alv/builtins.moon` and get
familiar with the relevant internal interfaces (especially `AST`, `Result`, and
`Scope`).

[lua]:          https://www.lua.org/
[moonscript]:   http://moonscript.org/
[builtins-req]: ../../reference/builtins.html#require
[builtins-imp]: ../../reference/builtins.html#import
[builtins-im_]: ../../reference/builtins.html#import*
[builtins-doc]: ../../reference/builtins.html#doc
[modules-midi]: ../../reference/midi.html
[ref-04-2-pop]: ../../reference/04-2_pure-operators.html
