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

Symbols need to start with a letter or one of the following special characters:

    - + * /
    _ . , =
    ! ? % $
    > < ~

After the first character, numbers are also allowed. There are two types of
symbols that are treated specially: symbols containing a slash (`math/+`), and
symbols starting and ending with asterisks (`*clock*`):

- Symbols containing slashes (except at beginning and end of the symbol) are
  split into multiple symbols, and looked up recursively in the scope. For
  example, `math/+` is found by first looking for a value for the symbol `math`,
  and then looking for the symbol `+` in that value. If the value for the
  symbol `math` is not a scope, an error is thrown.
- Symbols starting and ending with asterisks are called *dynamic symbols* and
  are looked up in a different way inside user-defined functions. This will be
  covered in detail later.
- The two special formats can be mixed: when evaluating `*hello*/world`,
  `alv` will look for the symbol `world` within the scope found by dynamically
  resolving `*hello*`.
