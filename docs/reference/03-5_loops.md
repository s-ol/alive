Loops are an evaltime construct that allows dealing with repetetive code and
lists of varying data, among other things.

The [loop][] and [recur][] ops are the basic building block of loops: [loop][]
begins a recursive loop, and [recur][] is used to restart it:

    (import* math logic string)

    (loop (n 5)
      (when (!= n 0)
        (print (str "hello #" n))
        (recur (- n 1))))

In this example, the `(when …)` expression is the body of the loop, i.e. the
code that is repeated multiple times. In the head of the loop, loop definitions
can be introduced in a key-value syntax like with [def][]. Loop definitions are
valid only within the loop body and can be changed for each iteration of the
loop. Here a single symbol `n` is defined to its starting value of `5`.

The loop body then starts being evaluated. Once it reaches the `(recur …)`
expression, the loop is restarted from the top, with the new value for `n`
given as the parameter. In this case, every new iteration of the loop has its
`n` decremented by one, until `n` is zero and therefore the `(recur …)`
expression is no longer reached.

Behind the scenes, [loop][] defines a new function for the dynamic symbol
`*recur*` and immediately invokes it with the default values, and [recur][]
simply calls this function. The example above could be equivalently rewritten
as follows:

    (import* math logic string)

    (defn loop-fn (n)
      (when (!= n 0)
        (print (str "hello #" n))
        (loop-fn (- n 1))))
    (loop-fn 5)
