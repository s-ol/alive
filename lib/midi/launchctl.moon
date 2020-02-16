import Stream, Const, Op from require 'core'
import InOut, apply_range from require 'lib.midi.core'
import bor, lshift from require 'bit32'

launch = InOut 'system:midi_capture_4', 'system:midi_playback_4'

color = (r, g) -> bor 12, r, (lshift g, 4)

class cc_seq extends Op
  @doc: "(launctl/cc-seq i start chan [steps [range]]) - CC-Sequencer

returns the value for the i-th step steps (buttons starting from start).
steps defaults to 8.

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- (num) [ 0 - num["

  destroy: =>
    launch\detach @mask if @mask

  new: =>
    @steps = {}
    @out = Stream 'num'

  setup: (@i, start, chan, steps=(Const.num 8), @range=Const.str 'uni') =>
    launch\detach @mask if @mask

    @start = start\const!\unwrap 'num'
    @chan = chan\const!\unwrap 'num'
    steps = steps\const!\unwrap 'num'

    while steps > #@steps
      table.insert @steps, 0
    while steps < #@steps
      table.remove @steps

    @mask = launch\attach { status: 'control-change', chan: @chan }, (_, _, cc, val) -> @change cc, val
    @out

  change: (cc, val) =>
    i = cc - @start
    if i < #@steps
      @steps[i+1] = val

  update: (dt) =>
    launch\tick!

    curr_i = (@i\unwrap 'num') % #@steps

    @out\set apply_range @range, @steps[curr_i+1]


class gate_seq extends Op
  @doc: "(launctl/gate-seq i start chan [steps]) - Gate-Sequencer

returns true or false for the i-th step steps (buttons starting from start).
steps defaults to 8."

  destroy: =>
    launch\detach @mask if @mask

  new: =>
    @steps = {}
    @out = Stream 'bool'

  setup: (@i, start, chan, steps=(Const.num 8)) =>
    launch\detach @mask if @mask

    for i=1, #@steps
      launch\send 'note-on', @chan, (@start+i), 0, color 0, 0

    @start = start\const!\unwrap 'num'
    @chan = chan\const!\unwrap 'num'
    steps = steps\const!\unwrap 'num'

    while steps > #@steps
      table.insert @steps, false
    while steps < #@steps
      table.remove @steps

    for i=1, steps
      @display i

    @mask = launch\attach { status: 'note-on', chan: @chan }, (_, _, note, _) ->
      @toggle note

    @out

  toggle: (note) =>
    i = note - @start
    val = @steps[i+1]
    if val != nil
      @steps[i+1] = not val
      curr_i = (@i\unwrap 'num') % #@steps
      @display i, i == curr_i

  display: (i, active) =>
    launch\send 'note-on', @chan, (@start + i), light @steps[i+1], active

  light = (set, active) ->
    set = if set then 'S' else ' '
    active = if active then 'A' else ' '
    color switch set .. active
      when '  ' then 0, 0
      when ' A' then 1, 1
      when 'S ' then 1, 0
      when 'SA' then 3, 1

  update: (dt) =>
    launch\tick!

    curr_i = (@i\unwrap 'num') % #@steps
    prev_i = (curr_i - 1) % #@steps

    @display curr_i, true
    @display prev_i, false

    @out\set @steps[curr_i+1]

{
  'gate-seq': gate_seq
  'cc-seq': cc_seq
}
