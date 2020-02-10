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

class tick extends Op
  @doc: "(tick freq) - count ticks

counts upwards at freq and returns the number of completed ticks."
  new: (...) =>
    super ...
    @phase = 0

  setup: (@freq) =>

  update: (dt) =>
    @freq\update dt

    @phase += dt / @freq\get!
    @value = math.floor @phase

{
  :lfo
  :tick
}
