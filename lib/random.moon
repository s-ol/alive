import Value, Error, Op, Input, match from require 'core.base'

apply_range = (range, val) ->
  if range\type! == 'str'
    switch range!
      when 'uni' then val / 128
      when 'bip' then val / 64 - 1
      when 'rad' then val / 64 * math.pi
      when 'deg' then val / 128 * 360
      else
        error Error 'argument', "unknown range '#{range!}'"
  elseif range.type == 'num'
    val / 128 * range!
  else
    error Error 'argument', "range has to be a string or number"

range_doc = "
range can be one of:
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

class num extends Op
num = Value.meta
  meta:
    name: 'num'
    summary: 'Generate a random number.'
    examples: { '(random/num [trigger] [range]))' }
    description: "Generate a random value in `range` when created and on `trig`.
#{range_doc}"

  value: class extends Op
    new: =>
      super 'num'
      @gen!

    gen: => @state = { math.random! }

    setup: (inputs) =>
      { trig, range } = match 'bang? any?', inputs
      super
        trig: trig and Input.event trig
        range: Input.value range or Value.str 'uni'

    tick: =>
      @gen! if @inputs.trig and @inputs.trig\dirty!
      @out\set apply_range @inputs.range, @state[1]

vec_ = (n) ->
  Value.meta
    meta:
      name: "vec#{n}"
      summary: 'Generate a random vector.'
      examples: { '(random/vec#{n} [trigger] [range]))' }
      description: "Generate a random vec#{n} in `range` when created and on `trig`.
#{range_doc}"

    value: class extends Op
      new: =>
        super "vec#{n}"
        @gen!

      gen: => @state = for i=1,n do math.random!

      setup: (inputs) =>
        { trig, range } = match 'bang? any?', inputs
        super
          trig: trig and Input.event trig
          range: Input.value range or Value.str 'uni'

      tick: =>
        @gen! if @inputs.trig and @inputs.trig\dirty!
        @out\set [apply_range @inputs.range, v for v in *@state]

{
  :num
  vec2: vec_ 2
  vec3: vec_ 3
  vec4: vec_ 4
}
