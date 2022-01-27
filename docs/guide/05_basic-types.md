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

```output
changes to files: values.alv
trace "hello": <str= "hello">
trace 2: <num= 2>
trace true: <bool= true>
```

On the left side of the colon, [trace][] prints the expression that it is
evaluating. On the right side, three pieces of information are shown:

- the *type*: `str`, `num`, `bool`
- the *value* itself: `"hello"`, `2`, `true` 
- the *kind* of the result: `=`

`=` means that these values are *constant* - they will not change by themselves
until the code is changed. For simple values like these that seems obvious, but
in `alv` we can also create values tha change over time, as we will see soon.
