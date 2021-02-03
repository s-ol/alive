Scopes contain symbol-result mappings and are used only at *evaltime*. Unlike
arrays and structs, which contain other types and have to either wholly be a
constant, ~-stream or !-steam, a single scope can contain all of these.

For this reason, scopes are used for metaprogramming and modules.
