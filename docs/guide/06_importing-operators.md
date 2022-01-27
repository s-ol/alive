Apart from [trace][], there are only very little builtin operators in `alv` -
you can see all of them in the *builtins* section of the [reference][:/:].
All of the 'real' functionality of `alv` is grouped into *modules*, that have
to be loaded individually. *Modules* help organize all of the operators so that
it is less overwhelming to look for a concrete feature. It is also possible to
create your own plugins as new modules, which will be covered in another guide
soon.

Let's try using the [`+` operator][:math/+:] from the [math/][] module. To use
operators from a module, we need to tell `alv` to load it first: We can load
*all* the operators from the [math/][] module into the current scope using the
[import*][] builtin:

    (import* math)
    (trace (+ 1 2))

prints

```output
trace (+ 1 2): <num= 3>
```

Because it can get a bit confusing when all imported operators are mixed in the
global scope, it is also possible to load the module into its own scope and use
it with a prefix. This is what the [import][] builtin is for:

    (import math)
    (trace (math/+ 1 2))
