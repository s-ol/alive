To reuse code across projects, `alv` code can be split up over multiple files
and loaded as *modules*.

## loading modules

To load modules, [require][], [import][] and [import*][] can be used:

- [require][] loads a module and returns its value.
- [import][] requires a module and makes its value available in a
  symbol with the same name. `(import my-module)` is equivalent to
  `(def my-module (require "my-module"))`.
- [import*][] loads a module and merges all exported symbols into the active
  scope. `(import* my-module)` is equivalent to `(use (require "my-module"))`.
  It assumes the module exports a scope with definitions to be imported.

[require][] can load two types of modules: *native* modules written in
Lua/MoonScript (such as everything listed in this reference), and modules
written in `alv` itself. The latter are looked up relative to the file
containing the `(require …)` expression, and are should match the module name
with the file extension `.alv`; i.e. `my-module.alv` for the example above.

If a module is imported multiple times, it is only evaluated once and its
result is reused.

## writing modules
When an alv script file is imported, its 'value' is that of the last expression
inside it:

`my-module.alv`

    (print "loading my-module...")
    
    4

`main.alv`

    (import* string)
    (print (str "my-module's value is " (require "my-module")))

```output
loading my-module...
my-module's value is 4
```

Often it is useful to export multiple values from a file, for example when
writing a library containing multiple functions. There are two operators to
allow this: [export][] and [export*][].

[export][] creates a new *scope* and evaluates all its arguments in it, just
like [do][]. However it doesn't return the result of the evaluations, but
rather the newly created scope. It can therefore be combined with [def][],
[defn][] etc. to export symbol definitions:

`my-module.alv`

    (import* math string)
    (export
      (def a-value 7)
      
      (defn print-doubled (x) (print (str x " doubled is " (* x 2)))))

`main.alv`

    (import* string)
    (import my-module)
    
    (print (str "my-module/a-value is " my-module/a-value))
    (my-module/print-doubled 4)

```output
my-module/a-value is 7
4 doubled is 8
```

[export*][] on the other hand operates on the containing scope rather than
creating a new one. When Used without any arguments, it returns the containing
scope itself and can be used to (re-)export everything that is currently
defined. When arguments are passed, only those symbols that are explicitly
mentioned are exported:

`my-module.alv`

    (def a 1)
    (def b 2)
    (def c 3)
    
    (export* a b)

`main.alv`

    (import* string)
    (import* my-module)
    
    (print (str "a is " a))
    (print (str "b is " b))
    (print (str "c is " c))

```output
a is 1
b is 2
reference error: undefined symbol 'c'
```
