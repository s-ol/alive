Both [import][] and [import*][] are actually shorthands and what they
accomplish can be done using the lower-level builtins [def][], [use][] and
[require][]. Here is how you could replace [import][]:

    #(with import:)
    (import math)
    (trace (math/+ 1 2))

    #(with def and require:)
    (def math (require "math"))
    (trace (math/+ 1 2))

[require][] returns a *scope*, which is defined as the symbol `math`.
Then `math/+` is resolved by looking for `+` in this nested scope. Note that
the symbol that the scope is defined as and the name of the module that is
loaded do not have to be the same, you could call the alias whatever you want:

    #(this not possible with import!)
    (def fancy-math (require "math"))
    (trace (fancy-math/+ 1 2))

Most of the time the name of the module makes a handy prefix already, so
[import][] can be used to save a bit of typing and make the code look a bit
cleaner. [import*][], on the other hand, defines every symbol from the imported
module individually. It could be implemented with [use][] like this:

    (use (require "math"))
    (trace (+ 1 2))

[use][] copies all symbol definitions from the scope it is passed to the
current scope.

Note that [import][], [import*][], [def][], and [use][] all can take multiple
arguments:

    #(using the shorthands:)
    (import* math logic)
    (import midi osc)

    #(using require, use and def:)
    (use (require "math") (require "logic"))
    (def midi (require "midi")
         osc  (require "osc"))

It is common to have an [import][] and [import*][] expression at the top of an
`alv` program to load all of the modules that will be used later, but the
modules don't necessarily have to be loaded at the very beginning, as long as
all symbols are defined before they are being used.

## nested scopes
Once a symbol is defined, it cannot be changed or removed:

    (def a 3)
    (def a 4) #(error!)

It is, however, possible to 'shadow' a symbol by re-defining it in a nested
scope: So far, all symbols we have defined - using `def`, [import][] and
[import*][] - have been defined in the *global scope*, the scope that is active
in the whole `alv` program. The [do][] builtin can be used to create a new
scope and evaluate some expressions in it:

    (import string)

    (def a 1
         b 2)

    (trace (.. "first: " a " " b))
    (do
      (def a 3)
      (trace (.. "second: " a " " b))
    (trace (.. "third: " a " " b))
```output
trace (.. "first: " a " " b): <Value str: first: 1 2>
trace (.. "second: " a " " b): <Value str: second: 3 2>
trace (.. "third: " a " " b): <Value str: third: 1 2>
```

As you can see, within a nested scope it is possible to overwrite a definition
from the parent scope. Symbols that are not explicitly redefined in a nested
scope keep their values, and changes in the nested scope do not impact the
parent scope.
