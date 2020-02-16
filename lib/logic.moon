import Stream, Op from require 'core'
unpack or= table.unpack

class BinOp extends Op
  new: (...) =>
    super ...
    @out = Stream 'bool'

  setup: (...) =>
    @children = { ... }
    assert #@children >= 2, "#{@} needs at least two parameters"
    @out

class eq extends BinOp
  @doc: "(eq a b [c]...)
(== a b [c]...) - check for equality"

  update: (dt) =>
    equal = true
    val = @children[1]\unwrap!
    for child in *@children[2,]
      equal and= val == child\unwrap!
    @out\set equal


class and_ extends BinOp
  @doc: "(and a b [c]...) - AND values"

  update: (dt) =>
    value = true
    for child in *@children
      value and= child\unwrap!
    @out\set value

class or_ extends BinOp
  @doc: "(or a b [c]...) - OR values

subtracts all other arguments from a"

  update: (dt) =>
    value = false
    for child in *@children
      value or= child\unwrap!
    @out\set value

class not_ extends Op
  @doc: "(not a) - boolean opposite"

  setup: (@a) =>
    @out = Stream 'bool'
    @out

  update: (dt) =>
    @out\set not @a\unwrap!

class bool extends Op
  @doc: "(bool a) - convert to bool"

  setup: (@a) =>
    @out = Stream 'bool'
    @out

  update: (dt) =>
    @out\set switch @a\unwrap!
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
