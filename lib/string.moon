import Op from require 'core'

class str extends Op
  @doc: "(str v1 [v2]...)
(.. v1 [v2]...) - concatenate/stringify values"

  setup: (...) =>
    @children = { ... }

  update: (dt) =>
    for child in *@children
      child\update dt

    @value = table.concat [tostring child\get! for child in *@children]

{
  :str, '..': str
}
