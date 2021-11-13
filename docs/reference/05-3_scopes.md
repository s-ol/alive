Scopes contain symbol-result mappings and are used only at *evaltime*. Unlike
arrays and structs, which contain other types and have to either wholly be a
constant, ~-stream or !-steam, a single scope can contain any combination of these.

Scopes can be created using the [export][] and [export*][] builtins and are often
returned from [require][].

They are mostly used for grouping definitions and can be indexed using the slash
(`/`) symbol. For more information on this, see section [3.1. symbol resolution](./03-1_symbol-resolution.html).
