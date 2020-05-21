import Constant, Op, Input, T, val, evt from require 'alv.base'

-- slower reference implementation
bjorklund = (n, k) ->
  full = ['1' for i=1,k]
  rest = ['0' for i=k,n-1]
  while #rest > 1
    next_full = {}
    while full[1] and rest[1]
      a = table.remove full
      b = table.remove rest
      table.insert next_full, a .. b
    while rest[1]
      table.insert full, table.remove rest
    full, rest = next_full, full

  if rest[1]
    table.insert full, rest[1]
  table.concat full, ''

-- faster implementation
bjorklund2 = (n, k) ->
  a, as = '1', k
  b, bs = '0', n - k

  while true
    if bs == 1 or bs == 0
      break
    elseif as < bs
      a, b = a .. b, b
      as, bs = as, bs - as
    else
      a, b = a .. b, a
      as, bs = bs, as - bs

  (string.rep a, as) .. (string.rep b, bs)

euclid = Constant.meta
  meta:
    name: 'euclid'
    summary: "Generate euclidean rhythms."
    examples: { '(euclid i n k)', '(euclid trigger! n k)' }
    description: "Generates bangs according to the Euclidean algorithm.

When fed a bang! trigger, steps forward to the next step on each trigger.
When fed a num~ or num! stream, outputs a bang if the corresponding step is on."

  value: class extends Op
    pattern = (evt.bang / val.num / evt.num) + val.num + val.num
    setup: (inputs) =>
      { trig, n, k } = pattern\match inputs

      @out or= T.bang\mk_evt!

      super
        trig: Input.hot trig
        n: Input.cold n
        k: Input.cold k

      if @inputs.trig\type! == T.bang
        @state or= 1
      else
        @state = nil

    tick: =>
      { :trig, :n, :k } = @unwrap_all!

      if @inputs.trig\type! == T.bang
        @state += 1
        if @state > n
          @state -= n

      i = 1 + (@state or trig % n)
      pat = bjorklund2 n, k
      if '1' == pat\sub i, i
        @out\set true

{
  :euclid
}
