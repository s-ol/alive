Every expression that is evaluated at *evaltime* returns a *result*, which may
or may not change at *runtime*. There are three *kinds* of results in `alv`.

# Constants
Constant results contain a single value that is generated at *evaltime* and do
not change at *runtime*. Operators that involve only constants generally
result in constants as well and are not processed at *runtime*. Literal strings
and numbers are constants.

Constants are denoted using the equals symbol (`=`) in documentation and
traces, e.g:

    (trace 4)
    #(trace 4: <num= 4>)

where `<num= 4>` denotes a constant of the type `num` with a value of `4`.

The [=][] builtin can be used to assert that a result is a constant. There is
no way to convert a signal or event stream to a constant.

# Signal Streams (~-streams)
Signal results contain a continuous value of a given type. A signal must have a
defined value at any given moment in time, including each *evaltime* evaluation.
While signals are considered to be continuous, for optimizations sake they are
processed as a series of discrete changes. Operators with signal inputs
generally are only reevaluated at *runtime* when the signal changed.

Signals are denoted using the tilde symbol (`~`) in documentation and traces,
e.g.:

    (import* time)
    (trace (lfo 2))
    #(trace (lfo 2): <num~ 0.0>
      trace (lfo 2): <num~ 0.0016211131633209>)

where `<num~ 1.0>` denotes a signal-stream of the type `num` with a current
value of `1.0`.

The [~][] builtin can be used to convert event streams to signal streams that
track the last received event. It is not possible or necessary to convert
constants to signal streams, as constants can always be passed in place of
signals.

# Event Streams (!-streams)
Event results may contain discrete values at instants in time, but are
undefined between such occurences. All values in a single event result share
one type. During a single tick of the `alv` scheduler, a given event result may
contain zero or more ordered values. Operators with event inputs must operate
each incoming event separately, as each event is considered to occur in a
separate moment.

Event streams are denoted using the bang symbol (`!`) in documentation and
traces, e.g.:

    (import* time)
    (trace (every 2))
    #(trace (lfo 2): <bang! true>
      trace (lfo 2): <bang! true>)

where `<bang! true>` denotes an event-stream of the type `bang` that fired with a
value of `true`.

The [!][] builtin can be used to convert signal streams or constants into
events by using an external impulse source.
