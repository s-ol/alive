import Stream, Op from require 'core'

class str extends Op
  @doc: "(str v1 [v2]...)
(.. v1 [v2]...) - concatenate/stringify values"

  setup: (...) =>
    @children = { ... }
    @out = Stream 'str'
    @out

  update: (dt) =>
    @out\set table.concat [tostring child\unwrap! for child in *@children]

{
  :str, '..': str
}
