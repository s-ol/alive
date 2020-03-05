% getting started
% - 
% -
# getting started with alive
`alive` is a language for creating and changing programs that continuosly
run. `alive` can be used to create music, visuals or installations, but by
itself does not create neither sound nor video. Rather, `alive` is used
together with other tools and synthesizers like [SuperCollider][supercollider],
[Pilot][pilot] and many more. `alive` takes the role of a 'conductor', telling
the other tools what to play when by sending commands to them using a variety of
protocols (such as OSC and MIDI).

Before we get to making sound though, we should learn a bit about the `alive`
programming language, and how to install and use it.

## installation
`alive` is written in the Lua programming langauge, and relies on a number of
other software projects to run. To manage these dependencies `luarocks` is
used, follow [this link][luarocks] for instructions on setting it up.
Once you have luarocks, you can install the dependencies for `alive`:

    $ luarocks install moonscript
    $ luarocks install osc
    $ luarocks install luasocket
    $ luarocks install luasystem
    $ luarocks install https://raw.githubusercontent.com/s-ol/lua-rtmidi/master/lua-rtmidi-dev-1.rockspec

If you have trouble installing some of the dependencies, note that `osc`,
`luasocket` and `lua-rtmidi` are optional, however you will not be able to use
the corresponding modules of the `alive` standard library if you do not install
them. To follow the later parts of this guide at least `osc` and `luasocket` are
required.

After installing the dependencies, you can clone the
[`alivecoding` repository][git] using git:

    $ git clone https://git.s-ol.nu/alivecoding.git

You should now be able to run `alive` from within the repository, but first you
will need to create a file for it to run. Create an empty file in the text
editor you want to use, and save it as `hello.alv` in the `alivecoding`
repository. Then launch the `alive` copilot like so:

    $ moon init.moon hello.alv
    hello.alv changed at 1583171231

You should see a similar output message, indicating that `alive` processed the
file. From now on, whenever you change `hello.alv` and save the file, `alive`
will reload it and execute your new code. When you are done, you can stop the
copilot at any time using `^C` (control-C).

## `alive` basics
`alive`'s syntax is very similar to Lisp. Expressions take the form of
parenthesized lists like `(head a b c...)`, where the first element of the list
(`head`) is the name of an operator of function, which defines what the
expression as a whole will do, while the other elements are parameters whose
meaning depends on the `head`. Let's start with a simple operator, `trace`:
`trace` is used to inspect values by printing them to the copilot. Enter the
following in your file and save it:

    (trace "hello world")

You should notice two things happening:

1. The copilot should print two new lines to the terminal:

       hello.alv changed at 1583424169
       trace "hello world": <Value str: hello world>

   In the first line, it notifies us that the file has changed. In the second
   line, we can see the output from `trace`: it lets us know that our input
   `"hello world"` evaluated to a `Value` with the type `str` (string) and
   contents `hello world`.
2. Your editor may notify you that `hello.alv` has changed, or reload the file
   for you. If there is an option like `always reload`, you might want to use
   it, since this will happen every time you make a change.

After reloading the file, you should see that the code has changed slightly:
It now looks like this:

    ([1]trace "hello world")

The `[1]` that the copilot added to our expression is that expression's `tag`.
In `alive`, every expression has a tag that helps the copilot to identify the
individual expressions as you make changes to your code. The copilot will make
sure that all expressions are tagged by adding missing tags when you save the
file, but you have to watch out not to duplicate a tag when copying and pasting
code. When you duplicate code that already has tags, you can either manually
change the tags to be unique, or simply delete the whole tag (including the
square brackets) and let the copilot generate a new one for you the next time
you save the file.

### basic types
Aside from strings, there are two more types of values that you can use when
writing alive programs: numbers and booleans. Numbers use the digits 0-9 and
can be integers, contain a decimal point, or start or end with a decimal point.
Numbers can start with a negetive sign. The following are all valid numbers:

    0
    12
    -7
    0.1
    10.
    .1
    123.

Strings can be written in two ways: using double quotes (`"`), as we did above,
or using single quotes (`'`). In both types of strings you can escape a quote
that otherwise would signify the end of the string using a single backslash,
and represent a backslash using two backlashes. The following are all valid
strings:

    "hello world"
    'hello world'
    "it's a beautiful day"
    'it\'s a beautiful day'
    "this is a backslash: \\"
    "this is a double quote: \""
    ""
    ''

There are only two boolean values, `true` and `false`:

    true
    false

You can try using `trace` with all of these values to get used to how they are
printed.

### importing modules
Apart from `trace`, there are only very little builtin operators in `alive` -
you can see all of them in the *builtins* section of the [reference][reference].
All of the 'real' functionality of `alive` is grouped into *modules*, that have
to be loaded individually. *Modules* help organize all of the operators, so that
it is less overwhelming to look for a concrete feature. It is also possible to
create your own plugins as new modules, which will be covered in another guide
soon.

Let's try using the [`+` operator][plus] from the `math` module. To use operators
from a module, we need to tell `alive` to load it first: We can load *all* the
operators from the `math` module into the current scope using the
[`import*`][import*] builtin:

    (import* math)
    (trace (+ 1 2))

prints

    trace (+ 1 2): <Value num: 3>

Because it can get a bit confusing when all imported operators are mixed in the
global scope, it is also possible to load the module into its own scope and use
it with a prefix. This is what the [`import`][import] builtin is for:

    (import math)
    (trace (math/+ 1 2))

### defining symbols
Both `import` and `import*` are actually shorthands for other builtins:
[`def`][def] and [`use`][use]. `def` is used to *define a symbol* in the
current scope. You can use it to associate a *symbol* (a name, like `hello`,
`trace` or `+`) with a value. After a symbol is defined, the name becomes an
alias that behaves like the value itself. For example, we can use `def` to
give the result of our calculation a name, and then refer to it in by that
symbol in the `trace` operator:

    (import* math)
    
    (def result (+ 1 2))
    (trace result)

Symbols need to start with a letter or one of the characters `-_+*/.!?=%`.
After the first character, numbers are also allowed. There are two formats of
symbols that are treated differently: symbols containing a slash (`math/+`), and
symbols starting and ending with asterisks (`*clock*`):

- Symbols containing slashes (except at beginning and end of the symbol) are
  split into multiple symbols, and looked up recursively in the scope. For
  example `math/+` is found by first looking for a value for the symbol `math`,
  and then looking for the symbol `+` in that value. If the value for the
  symbol `math` is not a scope, an error is thrown.
- Symbols starting and ending with asterisks are called `dynamic symbols` and
  are looked up in a different way inside user-defined functions. This will be
  covered in detail later.
- The two special formats can be mixed, for example `*hello*/world` will look
  for the symbol `world` within the scope found by dynamically resolving
  `*hello*`.

The `import` builtin is actually a shorthand for the following expression:

    (def math (require "math"))
    (trace (math/+ 1 2))

[`require`][require] returns a *scope*, which is defined as the symbol `math`.
Then `math/+` is resolved by looking for `+` in this nested scope. Note that
the symbol that the scope is defined as and the name of the module that is
loaded do not have to be the same, you could call the alias whatever you want:

    (def fancy-math (require "math"))
    (trace (fancy-math/+ 1 2))

In practice this is rarely useful, which is why the `require` shortcut exists.
The full version of `import*` on the other hand defines every symbol from the
imported module individually. The expanded version is the following:

    (use (require "math"))
    (trace (+ 1 2))

[`use`][use] copies all symbol definitions from the scope it is passed to the
current scope.

Note that `import`, `import*`, `def`, and `use` all can take multiple
arguments:

    (import* math logic)
    (import midi osc)

is the same as

    (use (require "math") (require "logic"))
    (def midi (require "midi")
         osc  (require "osc"))

It is common to have an `import` and `import*` expression at the top of an
`alive` program to load all of the modules that will be used later, but the
modules don't necessarily have to be loaded at the very beginning, as long as
all symbols are defined before they are being used.

### scopes
Once a symbol is defined, it cannot be changed or removed:

    (def a 3)
    (def a 4) #(error!)

However it is possible to 'shadow' a symbol with another one in a nested scope.
So far, all symbols we have defined - using `def`, `import` and `import*` -
have been defined in the *global scope*, the scope that is active in the whole
`alive` program. However some builtins create a new scope that their parameters
are evaluated in. One of them is [`do`][do], which does only that:

    (import string)
    
    (def a 1
         b 2)
    
    (trace (.. "first: " a " " b))
    (do
      (def a 3)
      (trace (.. "second: " a " " b))
    (trace (.. "third: " a " " b))

This example prints the following:

    trace (.. "first: " a " " b): <Value str: first: 1 2>
    trace (.. "second: " a " " b): <Value str: second: 3 2>
    trace (.. "third: " a " " b): <Value str: third: 1 2>

As you can see, within a nested scope it is possible to overwrite a definition
from the parent scope. Symbols that are not explicitly redefined in a nested
scope keep their values, and changes in the nested scope do not impact the
parent scope.

### functions
Another builtin that creates a nested scope is [`fn`][fn], which is used to
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

A function created using `fn` can be called like an operator. When a function
is called, the parameters to the function are defined with the names given in
the definition, and then the function body is executed. The previous example is
equivalent to the following:

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

    trace (+ a b): <Value num: 3>
    trace (+ a b): <Value num: 7>

In `alive`, functions are first-class values and can be passed around just like
numbers, strings etc. However it is very common to define a function with a
name, so there is the `defn` shorthand, which combines the `def` and `fn`
builtins into a single expression. Compare this equivalent definition of the
`add-and-trace` function:

    (defn add-and-trace (a b)
      (trace (+ a b)))

## making sound
As mentioned earlier, `alive` doesn't produce sound by itself. Instead, it is
paired with other tools, and takes the role of a 'Conductor', sending commands
and sequencing other tools.

For the sake of this guide, we will be controlling [Pilot][pilot], a simple
UDP-controlled synthesizer. You can go ahead and download and open it now.
You should see a small window with a bunch of cryptic symbols and a little
command line at the bottom. To verify that everything is working so far,
try typing in `84c` and hitting enter. This should play a short sound (the note
4C, played by the 8th default synthesizer voice in Pilot).

[supercollider]: https://supercollider.github.io/
[pilot]:         https://github.com/hundredrabbits/Pilot
[luarocks]:      https://github.com/luarocks/luarocks/#installing
[git]:           https://git.s-ol.nu/alivecoding
[reference]:     reference/
[plus]:          reference/math.html#+
[import*]:       reference/#import*
[import]:        reference/#import
[require]:       reference/#require
[use]:           reference/#use
[fn]:            reference/#fn
[defn]:          reference/#defn
