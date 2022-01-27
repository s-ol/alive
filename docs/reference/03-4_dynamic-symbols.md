Symbol definitions in `alv` normally follow 'lexical scoping' rules. That means
that symbols are looked up by following the scopes outwards according to the
syntactical nesting of expressions in the source code.

In the following snippet, for example, the symbol `hello` is resolved inside
`print-hello` by checking first the innermost scope (the function body), and
then the surrounding scope (the whole file), where the value `"original
message"` is found:

    (def hello "original message")
    (defn print-hello () (print hello))
    
    (do
      (def hello "overwritten message")
      (print-hello))
```output
original message
```

On the other hand, there are also *dynamic symbols*. Dynamic symbols are
symbols whose name starts and ends with an asterisk, like `*clock*` and
`*sym*`. Where functions are called, dynamic symbols are not looked up in the
scope that contains the *function definition*, but rather the scope containing
the *function call site*:
      
    (def *hello* "original message")
    (defn print-hello () (print *hello*))
    
    (do
      (def *hello* "overwritten message")
      (print-hello))
```output
overwritten message
```

This allows symbols to be *dynamically overwritten*.
