import Const, Op from require 'core'

class lfo extends Op
  @doc: "(lfo freq [wave]) - low-frequency oscillator

oscillates between 0 and 1 at the frequency freq.
wave selects the wave shape from the following (default sin):
- sin
- saw
- tri"

  tau = math.pi * 2
  new: (...) =>
    super ...
    @phase = 0

  default_wave = Const 'str', 'sin'
  setup: (@freq, @wave=default_wave) =>
    assert @freq, "lfo requires a frequency value"
    L\trace "setup #{@}, freq=#{@freq}, wave=#{@wave}"

  update: (dt) =>
    @freq\update dt
    @wave\update dt

    @phase += dt * @freq\get!
    @value = switch @wave\get!
      when 'sin' then .5 + .5 * math.cos @phase * tau
      when 'saw' then @phase % 1
      when 'tri' then math.abs (2*@phase % 2) - 1
      else error "unknown wave type"

class ramp extends Op
  @doc: "(ramp period [max]) - sawtooth lfo

ramps from 0 to max (default same as ramp) once every period seconds"

  new: (...) =>
    super ...
    @phase = 0

  setup: (@period, @max) =>
    assert @period, "tick requires a period value"

  update: (dt) =>
    @period\update dt
    max = if @max
      @max\update dt
      @max\get!
    else
      @period\get!

    @phase += dt / @period\get!

    if @phase >= 1
      @phase -= 1

    @value = @phase * max

class tick extends Op
  @doc: "(tick period) - count ticks

counts upwards every period seconds and returns the number of completed ticks."
  new: (...) =>
    super ...
    @phase = 0

  setup: (@period) =>
    assert @period, "tick requires a period value"

  update: (dt) =>
    @period\update dt

    @phase += dt / @period\get!
    @value = math.floor @phase

{
  :lfo
  :ramp
  :tick
}
