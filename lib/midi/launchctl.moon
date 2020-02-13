import Const, Op from require 'core'
import InOut from require 'lib.midi.core'
import bor, lshift from require 'bit32'

launch = InOut 'system:midi_capture_6', 'system:midi_playback_6'

color = (r, g) -> bor 12, r, (lshift g, 4)

class gate_seq extends Op
  @doc: "(launctl/gate-seq i start chan [steps]) - Gate-Sequencer

returns true or false for the i-th step steps (buttons starting from start)."

  destroy: =>
    launch\detach @mask if @mask

  new: =>
    @steps = {}
    @value = false

  setup: (@i, start, chan, steps=(Const.num 8)) =>
    launch\detach @mask if @mask

    @start = start\getc 'num'
    @chan = chan\getc 'num'
    steps = steps\getc 'num'

    while steps > #@steps
      table.insert @steps, false
    while steps < #@steps
      table.remove @steps

    @mask = launch\attach { status: 'note-on', chan: @chan }, (_, _, note, _) -> @toggle note

  toggle: (note) =>
    i = note - @start
    val = @steps[i+1]
    if val != nil
      @steps[i+1] = not val
      curr_i = (@i\get 'num') % #@steps
      launch\send 'note-on', @chan, note, light @steps[i+1], i == curr_i

  light = (set, active) ->
    set = if set then 'S' else ' '
    active = if active then 'A' else ' '
    color switch set .. active
      when '  ' then 0, 0
      when ' A' then 1, 0
      when 'S ' then 0, 1
      when 'SA' then 0, 3

  update: (dt) =>
    launch\tick!

    @i\update dt
    curr_i = (@i\get 'num') % #@steps
    prev_i = (curr_i - 1) % #@steps

    launch\send 'note-on', @chan, (@start + curr_i), light @steps[curr_i+1], true
    launch\send 'note-on', @chan, (@start + prev_i), light @steps[prev_i+1], false

    @value = @steps[curr_i+1]

{
  'gate-seq': gate_seq
}
