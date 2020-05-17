`alv`'s syntax is very similar to Lisp. Expressions take the form of
parenthesized lists like `(head a b c...)`, where the first element of the list
(`head`) is the name of an operator or function, which defines what the
expression as a whole will do, while the other elements are parameters whose
meaning depends on the `head`. Let's start with a simple operator, [print][]:
[print][] is used simply to print messages to the copilot console.

## expressions
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
this guideline, so you might just pick it up simply by following this guide.

## comments
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

[clojure-style]: https://github.com/bbatsov/clojure-style-guide
