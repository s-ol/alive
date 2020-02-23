import Registry, Value, Op from require 'core'
import monotime from require 'system'

delta = do
  period = 1 / 60
  
  local last
  ->

class clock extends Op
  new: =>
    super 'num'
    @impulses = { Registry.active!.kr }
    @out\set 0

  setup: (params) =>
    super params
    @last = monotime!

  tick: =>
    time = monotime!
    dt = time - @last
    if dt >= 1/60
      @out\set dt
      @last = time

class lfo extends Op
  @doc: "(lfo clock freq [wave]) - low-frequency oscillator

oscillates between 0 and 1 at the frequency freq.
wave selects the wave shape from the following (default sin):
- sin
- saw
- tri"

  tau = math.pi * 2
  new: =>
    super 'num'
    @phase = 0

  default_wave = Value.str 'sin'
  setup: (params) =>
    super params

    @inputs[3] or= default_wave
    @assert_types 'num', 'num', 'str'

  tick: =>
    -- if clock is dirty
    if @inputs[1].dirty
      dt, freq, wave = @unwrap_inputs!
      @phase += dt * freq
      @out\set switch wave
        when 'sin' then .5 + .5 * math.cos @phase * tau
        when 'saw' then @phase % 1
        when 'tri' then math.abs (2*@phase % 2) - 1
        else error "unknown wave type"

class ramp extends Op
  @doc: "(ramp clock period [max]) - sawtooth lfo

ramps from 0 to max (default same as ramp) once every period seconds."

  new: =>
    super 'num'
    @phase = 0

  setup: (params) =>
    super params
    assert @inputs[1].type == 'num', "tick requires a clock value"
    assert @inputs[2].type == 'num', "tick requires a period value"

  tick: =>
    -- if clock is dirty
    if @inputs[1].dirty
      dt, period, max = @unwrap_inputs!
      max or= period
      @phase += dt / period

      if @phase >= 1
        @phase -= 1

      @out\set @phase * max

class tick extends Op
  @doc: "(tick clock period) - count ticks

counts upwards by one every period seconds and returns the number of completed ticks."
  new: =>
    super 'num', 0
    @phase = 0

  setup: (params) =>
    super params
    @assert_types 'num', 'num'

  tick: (first) =>
    -- if clock is dirty
    if first or @inputs[1].dirty
      dt, period = @unwrap_inputs!
      @phase += dt / period

      next_num = math.floor @phase
      if next_num != @.out!
        @out\set next_num

class every extends Op
  @doc: "(every clock period) - trigger every period seconds

returns true once every period seconds."
  new: =>
    super 'bang'
    @phase = 0

  setup: (@period) =>
    super params
    @assert_types 'num', 'num'

  tick: (first) =>
    -- if clock is dirty
    if first or @inputs[1].dirty
      dt, period = @unwrap_inputs!
      @phase += dt / period

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
