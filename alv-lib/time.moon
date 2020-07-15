import Constant, EvtStream, IOStream, Error, Op, Input, T, sig, evt
  from require 'alv.base'
import monotime from require 'system'

class Clock extends IOStream
  new: (@frametime) =>
    super T.clock

    return unless monotime
    @last = monotime!
    @dt = 0

  poll: =>
    time = monotime!
    @dt = time - @last
    if @dt >= @frametime
      @set { dt: @dt, :time }
      @last = time

class ScaledClock extends EvtStream
  set: (val) => @value
  unwrap: => @value

clock = Constant.meta
  meta:
    name: 'clock'
    summary: "Create a clock source."
    examples: { '(clock)', '(clock fps)' }
    description: "Creates a new `time/clock!` stream.

The clock event stream is an IO that triggers other operators at a fixed
frame rate.

- `fps` has to be a num= constant and defaults to `60` if omitted."
  value: class extends Op
    new: (...) =>
      super ...
      @out or= Clock!

    setup: (inputs) =>
      fps = (-sig.num)\match inputs
      super fps: Input.hot fps or Constant.num 60
      @out.frametime = 1 / @inputs.fps!

    tick: =>
      @out.frametime = 1 / @inputs.fps!

scale_time = Constant.meta
  meta:
    name: 'scale-time'
    summary: "Scale clock time."
    examples: { '(scale-time [clock] scale)' }
    description: "Creates a new clock event stream scaled by `scale`.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `scale` should be a num~ stream."
  value: class extends Op
    new: (...) =>
      super ...
      @out or= T.clock\mk_evt!

    pattern = -evt.clock + sig.num + -sig.str
    setup: (inputs, scope) =>
      { clock, scale } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        scale: Input.cold scale

    tick: =>
      { :clock, :scale } = @unwrap_all!
      @out\set {k, v*scale for k,v in pairs clock}

lfo = Constant.meta
  meta:
    name: 'lfo'
    summary: "Low-frequency oscillator."
    examples: { '(lfo [clock] freq [wave])' }
    description: "Oscillates betwen `0` and `1` at the frequency `freq`.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `freq` should be a num~ stream.
- `wave` selects the wave shape from one of the following:
  - `'sin'` (the default)
  - `'saw'`
  - `'tri'`"
  value: class extends Op
    new: (...) =>
      super ...
      @state or= 0
      @out or= T.num\mk_sig!

    default_wave = Constant.str 'sin'
    pattern = -evt.clock + sig.num + -sig.str
    setup: (inputs, scope) =>
      { clock, freq, wave } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        freq: Input.cold freq
        wave: Input.hot wave or default_wave

    tau = math.pi * 2
    tick: =>
      if tick = @inputs.clock!
        @state += tick.dt * @inputs.freq!

      @out\set switch @inputs.wave!
        when 'sin' then .5 + .5 * math.cos @state * tau
        when 'saw' then @state % 1
        when 'tri' then math.abs (2*@state % 2) - 1
        else error Error 'argument', "unknown wave type '#{wave}'"

    vis: =>
      {
        type: 'bar'
        bar: @.out!
      }

ramp = Constant.meta
  meta:
    name: 'ramp'
    summary: "Sawtooth LFO."
    examples: { '(ramp [clock] period [max])' }
    description: "Ramps from `0` to `max` once every `period` seconds.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `period` should be a num~ stream.
- `max` should be a num~ stream and defaults to `period` if omitted."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= 0
      @out or= T.num\mk_sig!

    pattern = -evt.clock + sig.num + -sig.num
    setup: (inputs, scope) =>
      { clock, period, max } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        period: Input.cold period
        max: max and Input.cold max

    tick: =>
      { :clock, :period, :max } = @unwrap_all!
      max or= period

      @state += clock.dt / period
      while @state >= 1
        @state -= 1

      @out\set @state * max

    vis: =>
      {
        type: 'bar'
        bar: @state
      }

tick = Constant.meta
  meta:
    name: 'tick'
    summary: "Count ticks."
    examples: { '(tick [clock] period)' }
    description: "Counts upwards by one every `period` seconds.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `period` should be a num~ stream.
- returns a `num~` stream that increases by 1 every `period`."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= { phase: 0, count: 0 }
      @out or= T.num\mk_sig @state.count

    pattern = -evt.clock + sig.num
    setup: (inputs, scope) =>
      { clock, period } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        period: Input.cold period

    tick: =>
      @state.phase += @inputs.clock!.dt / @inputs.period!

      if @state.phase >= 1
        @state.phase -= 1
        @state.count += 1
        @out\set @state.count

    vis: => type: 'event'

every = Constant.meta
  meta:
    name: 'every'
    summary: "Emit events regularly."
    examples: { '(every [clock] period [evt])' }
    description: "Emits `evt` as an event once every `period` seconds.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `period` should be a num~ stream.
- `evt` can be a value of any type. It defaults to `bang`.
- the return type will be an event stream with the same type as `evt`."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= 0

    pattern = -evt.clock + sig.num + -sig!
    setup: (inputs, scope) =>
      { clock, period, evt } = pattern\match inputs
      super
        clock: Input.hot clock or scope\get '*clock*'
        period: Input.cold period
        evt: Input.cold evt or T.bang\mk_const true
      @out = @inputs.evt\type!\mk_evt!

    tick: =>
      @state += @inputs.clock!.dt / @inputs.period!

      if @state >= 1
        @state -= 1
        @out\set @inputs.evt!

val_seq = Constant.meta
  meta:
    name: 'val-seq'
    summary: "Emit a sequence of values as events over time."
    examples: { '(val-seq [clock] delay0 evt1 delay1 evt2 delay2…)' }
    description: "
Emits `evt1`, `evt2`, … as events with delays `delay0`, `delay1`, … in between.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `delay0`, `delay1`, … must be num~ streams.
- `evt1`, `evt2`, … must be signal streams of the same type.
- the return type will be an event stream with the same type as the `evt`s."
  value: class extends Op
    new: (...) =>
      super ...
      @state or= { i: 1, t: 0 }

    pair = (sig! + sig.num)\named('value', 'delay')
    pattern = -evt.clock + sig.num + pair*0

    inputify = (step) ->
      {
        delay: Input.cold step.delay
        value: if step.value then Input.hot step.value
      }

    setup: (inputs, scope) =>
      { clock, first, steps } = pattern\match inputs
      @out = steps[1].value\type!\mk_evt!
      table.insert steps, 1, { delay: first }
      super
        clock: Input.hot clock or scope\get '*clock*'
        steps: [inputify step for step in *steps]

    tick: =>
      if tick = @inputs.clock!
        @state.t += tick.dt

      change, current = false, nil
      while true
        current = @inputs.steps[@state.i]
        if @state.t >= current.delay!
          @state.t -= current.delay!
          @state.i = 1 + (@state.i % #@inputs.steps)
          change = true
        else
          break

      if current.value and (change or current.value\dirty!)
        @out\set current.value!

    vis: => step: @state.i

bang_seq = Constant.meta
  meta:
    name: 'bang-seq'
    summary: "Generate rhythms based on a sequence of delays"
    examples: { '(bang-seq [clock] delay0 delay1…)' }
    description: "
Emits `bang!`s with delays `delay0`, `delay1`, … in between.

- `clock` should be a `time/clock!` stream. This argument can be omitted
  and the stream be passed as a dynamic definition in `*clock*` instead.
- `delay0`, `delay1`, … must be num~ streams."

  value: class extends Op
    new: (...) =>
      super ...
      @out = T.bang\mk_evt!
      @state or= { i: 1, t: 0 }

    pattern = -evt.clock + sig.num*0
    setup: (inputs, scope) =>
      { clock, steps } = pattern\match inputs

      super
        clock: Input.hot clock or scope\get '*clock*'
        steps: [Input.cold step for step in *steps]

    tick: =>
      if tick = @inputs.clock!
        @state.t += tick.dt

      bang = false
      while true
        current = @inputs.steps[@state.i]!
        if @state.t >= current
          @state.t -= current
          @state.i = 1 + (@state.i % #@inputs.steps)
          bang = true
        else
          break

      if bang
        @out

    vis: => step: @state.i\set true

{
  :clock
  'scale-time': scale_time
  :lfo
  :ramp
  :tick
  :every
  'val-seq': val_seq
  'bang-seq': bang_seq

  '*clock*': with Clock 1/60
    .meta =
      name: '*clock*'
      summary: 'Default clock source (60fps).'
}
