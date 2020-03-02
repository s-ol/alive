import Registry, Value, Result, Op, ValueInput, EventInput, match
  from require 'core'
import monotime from require 'system'

class clock extends Op
  new: =>
    super 'clock', { dt: 0, time: monotime! }

  setup: =>
    @last = monotime!
    super kr: EventInput Registry.active!.kr

  tick: =>
    time = monotime!
    dt = time - @last
    if dt >= 1/60
      @out\set :dt, :time
      @last = time

class lfo extends Op
  @doc: "(lfo [clock] freq [wave]) - low-frequency oscillator

oscillates between 0 and 1 at the frequency freq.
wave selects the wave shape from the following:
- sin (default)
- saw
- tri"

  new: =>
    super 'num'
    @phase = 0

  default_wave = Result value: Value.str 'sin'
  setup: (inputs, scope) =>
    { clock, freq, wave } = match 'clock? num any?', inputs
    super
      clock: EventInput clock or scope\get '*clock*'
      freq: ValueInput freq
      wave: ValueInput wave or default_wave

  tau = math.pi * 2
  tick: =>
    if @inputs.clock\dirty!
      { :clock, :freq, :wave } = @unwrap_all!

      @phase += clock.dt * freq
      @out\set switch wave
        when 'sin' then .5 + .5 * math.cos @phase * tau
        when 'saw' then @phase % 1
        when 'tri' then math.abs (2*@phase % 2) - 1
        else error "unknown wave type"

class ramp extends Op
  @doc: "(ramp [clock] period [max]) - sawtooth lfo

ramps from 0 to max (default same as ramp) once every period seconds."

  new: =>
    super 'num'
    @phase = 0

  setup: (inputs, scope) =>
    { clock, period, max } = match 'clock? num num?', inputs
    super
      clock: EventInput clock or scope\get '*clock*'
      period: ValueInput period
      max: max and ValueInput max

  tick: =>
    clock_dirty = @inputs.clock\dirty!
    if clock_dirty
      { :clock, :period, :max } = @unwrap_all!
      max or= period
      @phase += clock.dt / period

      if @phase >= 1
        @phase -= 1

    if clock_dirty or (@inputs.max and @inputs.max\dirty!)
      @out\set @phase * max

class tick extends Op
  @doc: "(tick [clock] period) - count ticks

counts upwards by one every period seconds and returns the number of completed ticks."
  new: =>
    @phase, @count = 0, 0
    super 'num', @count

  setup: (inputs, scope) =>
    { clock, period } = match 'clock? num', inputs
    super
      clock: EventInput clock or scope\get '*clock*'
      period: ValueInput period

  tick: =>
    if @inputs.clock\dirty!
      { :clock, :period, :max } = @unwrap_all!
      @phase += clock.dt / period

      if @phase >= 1
        @phase -= 1
        @count += 1
        @out\set @count

class every extends Op
  @doc: "(every [clock] period) - trigger every period seconds

returns true once every period seconds."
  new: =>
    super 'bang'
    @phase = 0

  setup: (inputs, scope) =>
    { clock, period } = match 'clock? num', inputs
    super
      clock: EventInput clock or scope\get '*clock*'
      period: ValueInput period

  tick: =>
    if @inputs.clock\dirty!
      { :clock, :period, :max } = @unwrap_all!
      @phase += clock.dt / period

      if @phase >= 1
        @phase -= 1
        @out\set true

{
  :clock
  :lfo
  :ramp
  :tick
  :every
}
