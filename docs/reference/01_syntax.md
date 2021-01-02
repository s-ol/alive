`alv` programs consist of a series of expressions separated by chunks of
whitespace. Each expression may be either a literal constant or a cell.

# literal constants
There are three types of literals with different syntax:

## numbers
Numbers consist of the digits `0`-`9` and can optionally begin with a
negative sign and contain a decimal dot. The digits before or after the
decimal point may be left off, but a number needs to consist of at least one
digit.

The following are all valid numbers:

    0
    12
    -7
    0.1
    10.
    .1
    123.

The regular expression `-?(\d+\.\d*|\d*\.\d+|\d+)` matches all numbers. 

## strings
Strings are enclosed by either single (`'`) or double quotes (`"`). Backslashes
and either type of quote can be escaped by prefixing them with a single
backslash, i.e. the literal notation `"\\\""` evaluates to the string `\"`.

The following are all valid strings:

    "hello world"
    'hello world'
    "it's a beautiful day"
    'it\'s a beautiful day'
    "this is a backslash: \\"
    "this is a double quote: \""
    ""
    ''

## symbols
Symbols must start with a letter (`a`-`z` or `A`-`Z`) or one of the following
special characters:

    - + * /
    _ . , =
    ! ? % $
    > < ~

The remaining characters can be letters, special characters from this set, or
digits (`0`-`9`).

The following are all valid symbols:

    helloWORLD
    -
    /
    *dynamic*
    *+*
    var01
    _test
    foo$

The regular expression `[a-zA-Z\-+*\/_.,=!?%$~><][a-zA-Z0-9\-+*\/_.,=!?%$~><]*` matches all symbols. 

# cells
Cells consist of any number of subexpressions separated by chunks of whitespace
and enclosed in parentheses (`(` and `)`). A cell optionally contains a tag
immediately after the opening parenthesis. Whitespace between the opening
parenthesis and the first subexpression or the closing parenthesis and the last
subexpression is optional.

## tags
Tags consist of one or more digits (`0`-`9`) enclosed in square brackets (`[`
and `]`). `[1]` and `[255]` are examples of valid tags.

# whitespace
The space, tab, newline, and line-feed special characters constitute whitespace
and may be repeated any number of times to form a chunk. A chunk of whitespace
may also contain any number of comments, but may neither begin nor end with a
comment.

## comments
A comment begins with `#(` and ends with a matching parenthesis `)`. Comments
may contain other comments or cells.
