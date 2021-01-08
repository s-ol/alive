Arrays are composite types that contain a fixed number of values of the same
type. Arrays values can be created using the [`(array …)`][:array:] builtin,
which uses [Pure Op](04-2_pure-operators.html) semantics to construct an array
from its parameters, all of which have to be of the same type.

    (trace (array 1 2 3)) #(<num[3]= [1 2 3]>)

The type notation `num[3]` designates an array of three numbers, whereas the
value notation `[1 2 3]` is used to show the array contents.

The [array][:array/:] module provides *Op*s for working with arrays.
