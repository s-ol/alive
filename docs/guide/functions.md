Another builtin that creates a nested scope is [fn][], which is used to
create a *user-defined function*, which can be used to simplify repetitive
code, amongst other things:

    (import* math)

    (def add-and-trace
      (fn
        (a b)
        (trace (+ a b))))

    (add-and-trace 1 2)
    (add-and-trace 3 4)

Here a *function* `add-and-trace` is defined. When defining a function, first
the names of the parameters have to be given. The function defined here takes
two parameters, `a` and `b`. The last part of the function definition is called
the *function body*.

A function created using [fn][] can be called just like an operator. When a
function is called, the parameters to the function are defined with the names
given in the definition, and then the function body is executed. The previous
example is equivalent to the following:

    (import* math)

    (def add-and-trace
      (fn
        (a b)
        (trace (+ a b)))

    (do
      (let a 1
           b 2)
      (trace (+ a b)))

    (do
      (let a 3
           b 4)
      (trace (+ a b)))

and the output of both is:

    trace (+ a b): <num= 3>
    trace (+ a b): <num= 7>

In `alv`, functions are first-class values and can be passed around just like
numbers, strings, etc. However it is very common to define a function with a
name, so there is the `defn` shorthand, which combines the `def` and `fn`
builtins into a single expression. Compare this equivalent definition of the
`add-and-trace` function:

    (defn add-and-trace (a b)
      (trace (+ a b)))
