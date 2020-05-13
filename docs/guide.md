% getting started
% - 
% -
# getting started with alv
`alv` ("alive") is a language for creating and changing realtime programs while
they are running continuously. It can be used to create music, visuals or
installations, but by itself creates neither sound nor video. Rather, `alv` is
used together with other tools and synthesizers (for example
[SuperCollider][supercollider] or [Pilot][pilot]). In such an ensemble of
tools, `alive` takes the role of a 'conductor', telling the other tools what to
play when by sending commands to them using a variety of protocols, such as OSC
and MIDI.

Before we get to making sound though, we should learn a bit about the `alv`
programming language, and how to install and use it.

## installation
`alv` is written in the Lua programming language, and is compatible with both
Lua 5.3 and luajit.

### unix/linux and mac os
Your distribution should provide you with packages for Lua and Luarocks. On Mac
OS X, both are provided through [homebrew][homebrew]. After installing both of
these, you should be able to start the Lua interpreter from the shell:

    $ lua
    Lua 5.3.5  Copyright (C) 1994-2018 Lua.org, PUC-Rio
    > 

You can exit using `CTRL+C`. If the version you see is not 5.3, double check
your distribution packages or see if it was installed as `lua5.3` or `lua53`.
Similarily, you should be able to run `luarocks`, `luarocks53` or `luarocks5.3`:

    $ luarocks list
    
    Rocks installed for Lua 5.3
    ---------------------------

Again, double check your installation or try adding `--lua-version 5.3` if the
displayed version is not 5.3.

With everything reacdy to go, you can now install the dependencies for `alv`:

    $ luarocks install moonscript
    $ luarocks install luasystem
    $ luarocks install osc
    $ luarocks install luasocket
    $ luarocks install https://raw.githubusercontent.com/s-ol/lua-rtmidi/master/lua-rtmidi-dev-1.rockspec

While `moonscript` and `luasystem` are required by the core of `alv`, the
other packages (`osc`, `luasocket` and `lua-rtmidi`) are specific to some
modules of the alv language, and as long as you don't need to use these
modules their installation is optional.

In a later part of this guide, we will be using modules that require `osc` and
`luasocket`, so it is recommended to install at least these two. However it is
possible to follow a large portion of the guide without any of them. There will
be a note marking the parts of the guide where specific dependencies are
required.

After installing the dependencies, you can download the `alv` source code
from the [releases page][:*release*:], or clone the [git repository][:*repo*:]:

    $ git clone https://github.com/s-ol/alive.git

To run the copilot, open a shell and navigate into the repository. You can now
run the `hello.alv` example script using the following command:

    $ moon init.moon hello.alv
    hello.alv changed at 1585138092
    hello
    world!
    hello
    world!

You can stop it by pressing `^C` (control-C).

### windows
For Windows, a binary package is available from the latest
[github release][:*release*:]. It includes not only the `alv` source code, but
also a compiled version of Lua 5.3 as well as Luarocks and all of `alv`'s
dependencies.

To use the binary package, simply extract the archive and move the folder
wherever you want. You can now start the `hello.alv` example script by dragging
it onto the `copilot.bat` file in the folder, or by running the following
command from the main directory in `cmd.exe`:

    C:\…\alive>copilot.bat hello.alv
    hello.alv changed at 1585138092
    hello
    world!
    hello
    world!

You can stop it by pressing `^C` (control-C).

## evaluating code
To get started writing your own code, create an empty file in the text editor
you want to use, and save it as `test.alv` in the same folder as `hello.alv`.
Now restart the copilot as described above, but substituting the new file.

You should see a note indicating that `alv` processed the file. From now on,
whenever you change `test.alv` and save the file, `alv` will reload it and
execute your new code. When you are done, you can stop the copilot at any time
using `^C` (control-C).

`alv`'s syntax is very similar to Lisp. Expressions take the form of
parenthesized lists like `(head a b c...)`, where the first element of the list
(`head`) is the name of an operator or function, which defines what the
expression as a whole will do, while the other elements are parameters whose
meaning depends on the `head`. Let's start with a simple operator, [print][]:
[print][] is used simply to print messages to the copilot console. Enter the
following in your file and save it:

    (print "hello world!")

As soon as you save the file, you should notice two things happening:

1. The copilot should print two new lines to the terminal:

       hello.alv changed at 1583424169
       hello world!

   In the first line, it notifies us that the file has changed. In the second
   line, you can see the output from [print][].
2. The copilot will make a small modification to your file. Depending on the
   editor you are using, this may either result in you seeing the modification
   immediately, or a notice appearing that offers the option to reload the
   file. If it is the latter, confirm the notification to accept the changes.
   If there is an option to do so, you may want to configure your editor to
   always reload the file automatically.

The code should now look like this:

    ([1]print "hello world")

The `[1]` that the copilot added to our expression is that expression's `tag`.
In `alv`, every expression has a tag that helps the copilot to identify the
individual expressions as you make changes to your code. The copilot will make
sure that all expressions are tagged by adding missing tags when you save the
file, but you have to watch out not to duplicate a tag when copying and pasting
code. When you duplicate code that already has tags, you can either manually
change the tags to be unique, or simply delete the whole tag (including the
square brackets) and let the copilot generate a new one for you the next time
you save the file.

## syntax
As we just saw, *expressions* in alv take the form of parenthesized lists.
Elements of an expression have to be separated by whitespace, but any type of
and amount of whitespace is valid: feel free to use spaces, tabs, and newlines
to format code to your liking. The following are all equal and valid examples:

    (print "hello world")

    (+ 1
       2
       3)

    (print
    	"hello world")

      ( print "hello world" )

It is however recommended to follow the [clojure style guide][clojure-style] as
much as it does apply to alv. All further examples in this guide will respect
this guideline.

### basic types
Strings can be written in two ways: using double quotes (`"`), as we did above,
or using single quotes (`'`). In both types of strings, you can escape a quote
that otherwise would signify the end of the string by adding a single backslash
before it. Consequently, backslashes also have to be escaped in the same way.
The following are all valid strings:

    "hello world"
    'hello world'
    "it's a beautiful day"
    'it\'s a beautiful day'
    "this is a backslash: \\"
    "this is a double quote: \""
    ""
    ''

Aside from strings, there are two more types of values that you can use when
writing alv programs: numbers and booleans. Numbers use the digits 0-9 and
can be integers, contain a decimal point, or start or end with a decimal point.
Numbers can start with a negetive sign. The following are all valid numbers:

    0
    12
    -7
    0.1
    10.
    .1
    123.

There are only two boolean values, `true` and `false`:

    true
    false

The operator [print][], that we have been using above, only works on strings,
but there is a similar operator called [trace][] that can be used to inspect
any kind of value. It prints the value itself alongside more information, such
as the values type. Give it a try:

    (trace "hello")
    (trace 2)
    (trace true)

This will print the following:

    toast.alv changed at 1585138575
    trace <ValueStream str: hello>: <ValueStream str: hello>
    trace <ValueStream num: 2>: <ValueStream num: 2>
    trace <ValueStream sym: true>: <ValueStream bool: true>

### comments
To annotate your code, you can use comments. In `alv`, comments begin with
`#(` and end on a matching `)`. This way you can comment out a complete
expression simply by adding a `#` character in front.

    #(this is a comment)

    #(this is a long,
      multi-line comment,
      (and it also has nested parentheses).
      It ends after this sentence.)

You can put comments anywhere in your program where whitespace is allowed and
it will simply be ignored by `alv`.

### importing modules
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

    trace (+ 1 2): <Value num: 3>

Because it can get a bit confusing when all imported operators are mixed in the
global scope, it is also possible to load the module into its own scope and use
it with a prefix. This is what the [import][] builtin is for:

    (import math)
    (trace (math/+ 1 2))

### defining symbols
Another element of code in `alv` that we haven't discussed in detail yet are
*symbols*. *Symbols* (like `trace`, `import*` or `math/+`) are names that serve
as placeholders for previously *defined* values. When code is evaluated, symbols
are looked up in the current *scope* and replaced with the corresponding value
found there.

When an `alv` file starts running, a number of symbols are defined in the
default scope: These are the *builtins* mentioned above, and of which we have
already been using [trace][], [import][], and [import*][].

To *define a symbol* yourself, the [def][] builtin is used. It takes the symbol
as its first, and the value to associate as its second parameter. After a symbol
is defined, the name becomes an alias that behaves like the value itself. For
example, we can use [def][] to associate the result of our calculation with the
symbol `result`, and then refer to it by that symbol in the [trace][] operator:

    (import* math)

    (def result (+ 1 2))
    (trace result)

Symbols need to start with a letter or one of the characters `-_+*/.!?=%`.
After the first character, numbers are also allowed. There are two types of
symbols that are treated specially: symbols containing a slash (`math/+`), and
symbols starting and ending with asterisks (`*clock*`):

- Symbols containing slashes (except at beginning and end of the symbol) are
  split into multiple symbols, and looked up recursively in the scope. For
  example, `math/+` is found by first looking for a value for the symbol `math`,
  and then looking for the symbol `+` in that value. If the value for the
  symbol `math` is not a scope, an error is thrown.
- Symbols starting and ending with asterisks are called `dynamic symbols` and
  are looked up in a different way inside user-defined functions. This will be
  covered in detail later.
- The two special formats can be mixed: when evaluating `*hello*/world`,
  `alv` will look for the symbol `world` within the scope found by dynamically
  resolving `*hello*`.

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

### nested scopes
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

This example prints the following:

    trace (.. "first: " a " " b): <Value str: first: 1 2>
    trace (.. "second: " a " " b): <Value str: second: 3 2>
    trace (.. "third: " a " " b): <Value str: third: 1 2>

As you can see, within a nested scope it is possible to overwrite a definition
from the parent scope. Symbols that are not explicitly redefined in a nested
scope keep their values, and changes in the nested scope do not impact the
parent scope.

### defining functions
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

    trace (+ a b): <Value num: 3>
    trace (+ a b): <Value num: 7>

In `alv`, functions are first-class values and can be passed around just like
numbers, strings, etc. However it is very common to define a function with a
name, so there is the `defn` shorthand, which combines the `def` and `fn`
builtins into a single expression. Compare this equivalent definition of the
`add-and-trace` function:

    (defn add-and-trace (a b)
      (trace (+ a b)))

### evaltime and runtime
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
parameter to [time/tick][] controls how quickly it counts - try changing it to `0.5`
or `2`. As you can see, we can change [time/tick][] *while it is running*, but it
doesn't lose track of where it was!

All of the other things we learned above apply to streams of values as well -
we can use [def][] to store them in the scope, transform them using the ops
from the [math/][] module and so on:

    (import* time math)
    (def tik (tick 0.25))
    (trace (/ tik 4))

Note that if you leave the [time/tick][]'s *tag* in place when you move it into
the [def][] expression, it will keep on running steadily even then.

## making sound
As mentioned earlier, `alv` doesn't produce sound by itself. Instead, it is
paired with other tools, and takes the role of a 'Conductor', sending commands
and sequencing other tools.

For the sake of this guide, we will be controlling [Pilot][pilot], a simple
UDP-controlled synthesizer. You can go ahead and download and open it now.
You should see a small window with a bunch of cryptic symbols and a little
command line at the bottom. To verify that everything is working so far,
try typing in `84c` and hitting enter. This should play a short sound (the note
4C, played by the 8th default synthesizer voice in Pilot).

To talk to Pilot from `alv`, we will use the [pilot/][] module. Note that for
this module to work, you have to have the `osc` and `luasocket` dependencies
installed. To play the same sound we played by entering `84c` above every 0.5
seconds, we can use [time/every][] to send a `bang` to [pilot/play][]:

    (import* time)
    (import pilot)
    (pilot/play (every 0.5) 8 4 'c')

You can play with the voice, octave and note values a bit. To add a simple
melody, we can use [util/switch][], which will cycle through a list of
parameters when used together with [time/tick][]:

    (import* time util)
    (import pilot)
    (pilot/play (every 0.5) 8 4
      (switch (tick 0.5) 'c' 'd' 'a' 'f'))

Now we can have the voice change every other loop as well:

    (import* time util)
    (import pilot)
    (pilot/play (every 0.5)
      (switch (tick 4) 8 9)
      4 (switch (tick 0.5) 'c' 'd' 'a' 'f'))

To round off the sound a bit, we can turn on Pilot's reverb using
[pilot/effect][]. Add the following somewhere in your file:

    (pilot/effect "REV" 2 8)

Now it's time to add some rhythm. The kick drum is voice 12 by default,
and we can also add something like a snare on channel 3:

    (pilot/play (every 0.75)
      12 2 'd' 3)
    (pilot/play (every 2)
      13 4 'a' 4)

Note that since we are using multiple individual [time/every][] instances,
the timing of our voices relative to each other is not aligned - each voice
started playing when the file was first saved with it added, and kept the
rhythmn since. By deleting all their tags and re-saving the file, we can force
`alv` to re-instantiate them all at the same time, thereby synchronising
them.

[supercollider]: https://supercollider.github.io/
[pilot]:         https://github.com/hundredrabbits/Pilot
[homebrew]:      https://brew.sh
[luarocks]:      https://github.com/luarocks/luarocks/#installing
[reference]:     reference/
[clojure-style]: https://github.com/bbatsov/clojure-style-guide
[pd]:            http://puredata.info/
[max]:           https://cycling74.com/products/max
[vvvv]:          https://vvvv.org/
