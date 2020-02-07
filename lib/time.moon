import Op, Const from require 'base'

class lfo extends Op
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
