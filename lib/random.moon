import ValueStream, Error, Op, Input, val, evt from require 'alv.base'

apply_range = (range, val) ->
  if range\type! == 'str'
    switch range!
      when 'uni' then val
      when 'bip' then val*2 - 1
      when 'rad' then val*2 * math.pi
      when 'deg' then val * 360
      else
        error Error 'argument', "unknown range '#{range!}'"
  elseif range\type! == 'num'
    val * range!
  else
    error Error 'argument', "range has to be a string or number"

range_doc = "
range can be one of:
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- 'deg' [ 0 - 360[
- (num) [ 0 - num["

pattern = -evt.bang + -(val.num / val.str)

num = ValueStream.meta
  meta:
    name: 'num'
    summary: 'Generate a random number.'
    examples: { '(random/num [trigger] [range]))' }
    description: "Generate a random value in `range` when created and on `trig`.
#{range_doc}"

  value: class extends Op
    new: (...) =>
      super ...
      @out or= ValueStream 'num'
      @state or @gen!

    gen: => @state = math.random!

    setup: (inputs) =>
      { trig, range } = pattern\match inputs
      super
        trig: trig and Input.hot trig
        range: Input.hot range or ValueStream.str 'uni'

    tick: =>
      @gen! if @inputs.trig and @inputs.trig\dirty!
      @out\set apply_range @inputs.range, @state

vec = (n) ->
  ValueStream.meta
    meta:
      name: "vec#{n}"
      summary: 'Generate a random vector.'
      examples: { '(random/vec#{n} [trigger] [range]))' }
      description: "Generate a random vec#{n} in `range` when created and on `trig`.
#{range_doc}"

    value: class extends Op
      new: (...) =>
        super ...
        @out or= ValueStream "vec#{n}"
        @state or @gen!

      gen: => @state = for i=1,n do math.random!

      setup: (inputs) =>
        { trig, range } = pattern\match inputs
        super
          trig: trig and Input.hot trig
          range: Input.hot range or ValueStream.str 'uni'

      tick: =>
        @gen! if @inputs.trig and @inputs.trig\dirty!
        @out\set [apply_range @inputs.range, v for v in *@state]

{
  :num
  vec2: vec 2
  vec3: vec 3
  vec4: vec 4
}
