import Stream, Op, Scope, eval from require 'core'

class ar_core extends Op
  @doc: "(ar-core attack release gate)
((ar attack release) gate) - AR envelope

goes from 0 to 1 in attack seconds, holds while gate is on, then goes back to 0 in release seconds."

  new: (...) =>
    super ...
    @out = Stream 'num', 0

  setup: (@a, @r, @gate) =>
    assert @a, "ar requires an attack value"
    assert @r, "ar requires a release value"
    assert @gate, "ar requires a gate value"
    @out

  update: (dt) =>
    slope = if (@gate\unwrap 'bool') then (@a\unwrap! or 0.1) else -(@r\unwrap! or 0.5)

    @out\set math.min 1, math.max 0, @out\unwrap! + dt / slope

scope = Scope.from_table { 'ar-core': ar_core }
scope\set 'ar', eval '(fn (a r) (fn (gate) (ar-core a r gate)))', scope
scope
