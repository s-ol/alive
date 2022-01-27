import Constant, Op, Input, T, sig, evt, any from require 'alv.base'

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
    if as < 2 or bs < 2
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
    examples: { '(euclid trig! n k)', '(euclid i n k)' }
    description: "Generates bangs according to the Euclidean algorithm.

When fed a bang! trigger, steps forward to the next step on each trigger.
When fed a num~ or num! stream, outputs a bang if the corresponding step is on."

  value: class extends Op
    pattern = (evt.bang / any.num) + sig.num + sig.num
    setup: (inputs) =>
      { trig, n, k } = pattern\match inputs

      @out or= T.bang\mk_evt!

      if trig\type! == T.bang
        @state or= 1
      else
        @state = nil

      super
        trig: Input.hot trig
        n: Input.cold n
        k: Input.cold k

    tick: =>
      { :trig, :n, :k } = @unwrap_all!
      n = math.floor n
      k = math.floor k

      if @inputs.trig\type! == T.bang
        @state += 1
        if @state >= n
          @state -= n

      i = 1 + (@state or trig % n)
      pat = bjorklund2 n, k
      if '1' == pat\sub i, i
        @out\set true

trigseq = Constant.meta
  meta:
    name: 'trigseq'
    summary: "Generate rhythms based on a trigger-sequence"
    examples: { '(trigseq trig! s1 s2…)', '(trigseq i s1 s2…)' }
    description: "Generates bangs according to the sequence `s1`, `s2`, …

Each step should be a bool~ that determines whether a bang should be emitted on
that step or not.

When fed a bang! trigger, steps forward to the next step on each trigger.
When fed a num~ or num! stream, outputs a bang if the corresponding step is on."

  value: class extends Op
    pattern = (evt.bang / any.num) + sig.bool*0
    setup: (inputs) =>
      { trig, steps } = pattern\match inputs

      @out or= T.bang\mk_evt!

      super
        trig: Input.hot trig
        steps: [Input.cold s for s in *steps]

      if @inputs.trig\type! == T.bang
        @state or= 1
      else
        @state = nil

    tick: =>
      n = #@inputs.steps
      if @inputs.trig\type! == T.bang
        @state += 1
        if @state >= n
          @state -= n

      i = 1 + (@state or trig % n)
      if @inputs.steps[i]!
        @out\set true

Constant.meta
  meta:
    name: 'rhythm'
    summary: "Rhythm-generation and sequencing."

  value:
    :euclid
    :trigseq
