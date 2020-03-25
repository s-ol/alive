import
  ValueStream, EventStream, IOStream,
  Error, Op, Input, val, evt
from require 'core.base'
import monotime from require 'system'

class Clock extends IOStream
  new: (@frametime) =>
    super 'clock'

    return unless monotime
    @last = monotime!
    @dt = 0
    @is_dirty = false

  tick: =>
    time = monotime!
    @dt = time - @last
    @is_dirty = if @dt >= @frametime
      @last = time
      true
    else
      false

  unwrap: =>
    dt = @dt
    time = @last
    { :dt, :time }

  dirty: => @is_dirty

clock = ValueStream.meta
  meta:
    name: 'clock'
    summary: "Create a clock source."
    examples: { '(clock)', '(clock fps)' }
    description: "
IO that triggers other operators at a fixed frame rate.
`fps` defaults to 60 and has to be an eval-time constant"
  value: class extends Op
    new: (...) =>
      super ...
      @out or= Clock!

    setup: (inputs) =>
      fps = (-val.num)\match inputs
      super fps: Input.hot fps or ValueStream.num 60
      @out.frametime = 1 / @inputs.fps!

    tick: =>
      @out.frametime = 1 / @inputs.fps!

lfo = ValueStream.meta
  meta:
    name: 'lfo'
    summary: "Low-frequency oscillator."
    examples: { '(lfo [clock] freq [wave])' }
    description: "
oscillates between 0 and 1 at the frequency freq.
wave selects the wave shape from the following:
- `'sin'` (default)
- `'saw'`
- `'tri'`"
  value: class extends Op
    new: (...) =>
      super ...
      @state or= 0
      @out or= ValueStream 'num'

    default_wave = ValueStream.str 'sin'
    pattern = -evt.clock + val.num + -val.str
    setup: (inputs, scope) =>
      { clock, freq, wave } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        freq: Input.cold freq
        wave: Input.hot wave or default_wave

    tau = math.pi * 2
    tick: =>
      if @inputs.clock\dirty!
        @state += @inputs.clock!.dt * @iputs.freq!

      @out\set switch @inputs.wave!
        when 'sin' then .5 + .5 * math.cos @state * tau
        when 'saw' then @state % 1
        when 'tri' then math.abs (2*@state % 2) - 1
        else error Error 'argument', "unknown wave type '#{wave}'"

ramp = ValueStream.meta
  meta:
    name: 'ramp'
    summary: "Sawtooth LFO."
    examples: { '(ramp [clock] period [max])' }
    description: "
ramps from 0 to max (default same as ramp) once every period seconds."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= 0
      @out or= ValueStream 'num'

    pattern = -evt.clock + val.num + -val.num
    setup: (inputs, scope) =>
      { clock, period, max } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        period: Input.cold period
        max: max and Input.cold max

    tick: =>
      clock_dirty = @inputs.clock\dirty!
      if clock_dirty
        period = @inputs.period!
        max = (@inputs.max or @inputs.period)!
        @phase += @inputs.clock!.dt / period

        while @phase >= 1
          @phase -= 1

        @out\set @phase * max

tick = ValueStream.meta
  meta:
    name: 'tick'
    summary: "Count ticks."
    examples: { '(tick [clock] period)' }
    description: "
counts upwards by one every period seconds and returns the number of completed
ticks."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= { phase: 0, count: 0 }
      @out or= ValueStream 'num', @state.count

    pattern = -evt.clock + val.num
    setup: (inputs, scope) =>
      { clock, period } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        period: Input.cold period

    tick: =>
      @state.phase += @inputs.clock!.dt / @inputs.period!

      while @state.phase >= 1
        @state.phase -= 1
        @state.count += 1
        @out\set @state.count

every = ValueStream.meta
  meta:
    name: 'every'
    summary: "Emit bangs."
    examples: { '(every [clock] period)' }
    description: "returns true once every period seconds."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= 0
      @out or= EventStream 'bang'

    pattern = -evt.clock + val.num
    setup: (inputs, scope) =>
      { clock, period } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        period: Input.cold period

    tick: =>
      @state += @inputs.clock!.dt / @inputs.period!

      while @state >= 1
        @state -= 1
        @out\add true

{
  :clock
  :lfo
  :ramp
  :tick
  :every
  '*clock*': with Clock 1/60
    .meta =
      name: '*clock*'
      summary: 'Default clock source (60fps).'
}
