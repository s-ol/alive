import Op from require 'core'
unpack or= table.unpack

class BinOp extends Op
  setup: (...) =>
    @children = { ... }
    assert #@children >= 2, "#{@} needs at least two parameters"

  update: (dt) =>
    for child in *@children
      child\update dt

class eq extends BinOp
  @doc: "(eq a b [c]...)
(== a b [c]...) - check for equality"

  update: (dt) =>
    super\update dt

    @value = true
    val = @children[1]\get!
    for child in *@children[2,]
      @value and= val == child\get!


class and_ extends BinOp
  @doc: "(and a b [c]...) - AND values"

  update: (dt) =>
    super\update dt

    @value = true
    for child in *@children
      @value and= child\get!

class or_ extends BinOp
  @doc: "(or a b [c]...) - OR values

subtracts all other arguments from a"

  update: (dt) =>
    super\update dt

    @value = false
    for child in *@children
      @value or= child\get!

class not_ extends Op
  @doc: "(not a) - boolean opposite"

  setup: (@a) =>

  update: (dt) =>
    @a\update dt

    @value = not @a\get!

class bool extends Op
  @doc: "(bool a) - convert to bool"

  setup: (@a) =>

  update: (dt) =>
    @a\update dt

    @value = switch @a\get!
      when false, nil, 0
        false
      else
        true

{
  '==': eq
  :eq
  and: and_
  or: or_
  not: not_
  :bool
}
