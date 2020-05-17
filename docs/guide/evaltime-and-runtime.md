So far, `alv` may seem a lot like any other programming language - you write
some code, save the file, and it runs, printing some output. "What about the
'continuously running' aspect from the introduction?", you may ask yourself. 

So far, we have only seen *evaltime* execution in alv - but there is also
*runtime* behavior. At *evaltime*, that is whenever there is change to the
source code, `alv` behaves similar to a Lisp. This is the part we have seen
so far. But once one such *eval cycle* has executed, *runtime* starts, and
`alv` behaves like a dataflow system like [PureData][pd], [Max/MSP][max] or
[vvvv][vvvv].

What looked so far like static constants are actually *streams* of values.
Whenever an input to an operator changes, the operator (may) update and respond
with a change to its output as well. To see this in action, we need to start
with a changing value. Number literals like `1` and `2`, which we used so far,
are *evaltime constant*, which means simply that they will never update. Since
all inputs to our [math/+][] operator are *evaltime constant*, the result is
constant as well. To get some *runtime* activity, we have to introduce a
side-effect input from somewhere outside the system.

The [time/][] module contains a number of operators whose outputs update
over time. Lets take a look at [time/tick][]:

    (import* time)
    (trace (tick 1))

This will print a series of numbers, incrementing by 1 every second. The
parameter to [time/tick][] controls how quickly it counts - try changing it to
`0.5` or `2`. As you can see, we can change [time/tick][] *while it is
running*, but it doesn't lose track of where it was!

All of the other things we learned above apply to streams of values as well -
we can use [def][] to store them in the scope, transform them using the ops
from the [math/][] module and so on:

    (import* time math)
    (def tik (tick 0.25))
    (trace (/ tik 4))

Note that if you leave the [time/tick][]'s *tag* in place when you move it into
the [def][] expression, it will keep on running steadily even then.

[pd]:   http://puredata.info/
[max]:  https://cycling74.com/products/max
[vvvv]: https://vvvv.org/
