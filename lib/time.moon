import Registry, Value, IO, Op, Input, match
  from require 'core.base'
import monotime from require 'system'

class Clock extends IO
  new: (@frametime) =>
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

  dirty: => @is_dirty

class clock extends Op
  @doc: "(clock [fps]) - a clock source

IO that triggers other operators at a fixed frame rate.
fps defaults to 60 and has to be an eval-time constant"

  new: => super 'clock'

  setup: (inputs) =>
    { fps } = match 'num?', inputs
    super fps: Input.value fps or Value.num 60

  tick: =>
    if @inputs.fps\dirty!
      @out\set Clock 1 / @inputs.fps!

class lfo extends Op
  @doc: "(lfo [clock] freq [wave]) - low-frequency oscillator

oscillates between 0 and 1 at the frequency freq.
wave selects the wave shape from the following:
- sin (default)
- saw
- tri"

  new: =>
    super 'num'
    @state.phase or= 0

  default_wave = Value.str 'sin'
  setup: (inputs, scope) =>
    { clock, freq, wave } = match 'clock? num any?', inputs
    super
      clock: Input.io clock or scope\get '*clock*'
      freq: Input.value freq
      wave: Input.value wave or default_wave

  tau = math.pi * 2
  tick: =>
    if @inputs.clock\dirty!
      { :clock, :freq, :wave } = @unwrap_all!

      @state.phase += clock.dt * freq
      @out\set switch wave
        when 'sin' then .5 + .5 * math.cos @state.phase * tau
        when 'saw' then @state.phase % 1
        when 'tri' then math.abs (2*@state.phase % 2) - 1
        else error "unknown wave type"

class ramp extends Op
  @doc: "(ramp [clock] period [max]) - sawtooth lfo

ramps from 0 to max (default same as ramp) once every period seconds."

  new: =>
    super 'num'
    @state.phase or= 0

  setup: (inputs, scope) =>
    { clock, period, max } = match 'clock? num num?', inputs
    super
      clock: Input.io clock or scope\get '*clock*'
      period: Input.value period
      max: max and Input.value max

  tick: =>
    clock_dirty = @inputs.clock\dirty!
    if clock_dirty
      { :clock, :period, :max } = @unwrap_all!
      max or= period
      @state.phase += clock.dt / period

      while @state.phase >= 1
        @state.phase -= 1

    if clock_dirty or (@inputs.max and @inputs.max\dirty!)
      @out\set @state.phase * max

class tick extends Op
  @doc: "(tick [clock] period) - count ticks

counts upwards by one every period seconds and returns the number of completed ticks."
  new: =>
    super 'num', 0
    @state.phase or= 0
    @state.count or= 0

  setup: (inputs, scope) =>
    { clock, period } = match 'clock? num', inputs
    super
      clock: Input.io clock or scope\get '*clock*'
      period: Input.value period

  tick: =>
    if @inputs.clock\dirty!
      { :clock, :period, :max } = @unwrap_all!
      @state.phase += clock.dt / period

      while @state.phase >= 1
        @state.phase -= 1
        @state.count += 1
        @out\set @state.count

class every extends Op
  @doc: "(every [clock] period) - trigger every period seconds

returns true once every period seconds."
  new: =>
    super 'bang'
    @state.phase or= 0

  setup: (inputs, scope) =>
    { clock, period } = match 'clock? num', inputs
    super
      clock: Input.io clock or scope\get '*clock*'
      period: Input.value period

  tick: =>
    if @inputs.clock\dirty!
      { :clock, :period, :max } = @unwrap_all!
      @state.phase += clock.dt / period

      while @state.phase >= 1
        @state.phase -= 1
        @out\set true

{
  :clock
  :lfo
  :ramp
  :tick
  :every
  '*clock*': Value 'clock', Clock 1/60
}
