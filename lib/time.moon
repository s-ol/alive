import Stream, Const, Op from require 'core'

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
    print "creating LFO"
    @out = Stream 'num'
    @phase = 0

  default_wave = Const 'str', 'sin'
  setup: (@freq, @wave=default_wave) =>
    assert @freq, "lfo requires a frequency value"
    L\trace "setup #{@}, freq=#{@freq}, wave=#{@wave}"
    @out

  update: (dt) =>
    @phase += dt * @freq\unwrap 'num'
    @out\set switch @wave\unwrap!
      when 'sin' then .5 + .5 * math.cos @phase * tau
      when 'saw' then @phase % 1
      when 'tri' then math.abs (2*@phase % 2) - 1
      else error "unknown wave type"

class ramp extends Op
  @doc: "(ramp period [max]) - sawtooth lfo

ramps from 0 to max (default same as ramp) once every period seconds"

  new: (...) =>
    super ...
    @out = Stream 'num'
    @phase = 0
    @out

  setup: (@period, @max) =>
    assert @period, "tick requires a period value"

  update: (dt) =>
    period = @period\unwrap 'num'
    max = if @max then @max\unwrap! else period
    @phase += dt / period

    if @phase >= 1
      @phase -= 1

    @out\set @phase * max

class tick extends Op
  @doc: "(tick period) - count ticks

counts upwards by one every period seconds and returns the number of completed ticks."
  new: (...) =>
    super ...
    @out = Stream 'num'
    @phase = 0

  setup: (@period) =>
    assert @period, "tick requires a period value"
    @out

  update: (dt) =>
    @phase += dt / @period\unwrap 'num'
    @out\set math.floor @phase

class every extends Op
  @doc: "(every period) - sometimes true

returns true once every period seconds."
  new: (...) =>
    super ...
    @out = Stream 'bool'
    @phase = 0

  setup: (@period) =>
    assert @period, "every requires a period value"
    @out

  update: (dt) =>
    @phase += dt / @period\unwrap 'num'
    if @phase > 1
      @phase -= 1
      @out\set true
    else
      @out\set false

{
  :lfo
  :ramp
  :tick
  :every
}
