Structs are composite types that contain values of different types associated
with a set of string keys. The set of keys and their corresponding value types
is fixed at *runtime*.

Struct values can be created using the the [`(struct …)`][:struct:] builtin,
which uses [Pure Op](04-2_pure-operators.html) semantics to construct a struct
from its parameters. The keys have to be constants.

    (trace (struct "a" 1 "b" 'hello world')) <{a: num b: str}= {a: 1 b: "hello world"}>

The type notation `{a: num b: str}` designates a struct type with the key `a`
mapping to a value of type `num` and the key `b` mapping to a value of type
`str` respectively, whereas the value notation `{a: 1 b: "hello world"}` shows
the struct contents.

The [struct-][:struct-/:] module provides *Op*s for working with arrays.
