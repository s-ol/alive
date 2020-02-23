import Value, Op from require 'core'
import apply_range from require 'lib.midi.core'
import bor, lshift from require 'bit32'

unpack or= table.unpack
color = (r, g) -> bor 12, r, (lshift g, 4)

class cc_seq extends Op
  @doc: "(launctl/cc-seq port i start chan [steps [range]]) - CC-Sequencer

returns the value for the i-th step steps (buttons starting from start).
steps defaults to 8.

range can be one of:
- 'raw' [ 0 - 128[
- 'uni' [ 0 - 1[ (default)
- 'bip' [-1 - 1[
- 'rad' [ 0 - tau[
- (num) [ 0 - num["

  new: =>
    super 'num'
    @steps = {}

  setup: (params) =>
    super params

    @inputs[5] or= Value.num 8
    @inputs[6] or= Value.str 'uni'
    assert #@inputs == 6
    assert @inputs[6].type == 'num' or @inputs[6].type == 'str'
    @assert_first_types 'midi/port', 'num', 'num', 'num', 'num'
    @impulses = { @inputs[1]\unwrap! }

    if not @out\unwrap!
      @out\set apply_range @inputs[6], 0

  tick: (first) =>
    port = @inputs[1]\unwrap!
    _, i, start, chan, steps = unpack @inputs

    if first or @inputs[5]\dirty!
      steps = @inputs[5]!
      while steps > #@steps
        table.insert @steps, 0
      while steps < #@steps
        table.remove @steps

    curr_i = i\unwrap! % #@steps
    changed = false

    for msg in port\receive!
      if msg.status == 'control-change' and msg.chan == chan!
        rel_i = msg.a - start!
        if rel_i >= 0 and rel_i < #@steps
          @steps[rel_i+1] = msg.b
          changed = rel_i == curr_i

    if changed or i\dirty! or start\dirty! or chan\dirty! or steps\dirty!
      @out\set apply_range @inputs[6], @steps[curr_i+1]

class gate_seq extends Op
  @doc: "(launctl/gate-seq port i start chan [steps]) - Gate-Sequencer

returns true or false for the i-th step steps (buttons starting from start).
steps defaults to 8."

  new: =>
    super 'bool', false
    @steps = {}

  setup: (params) =>
    super params

    @inputs[5] or= Value.num 8
    @inputs[6] or= Value.str 'uni'
    @assert_types 'midi/port', 'num', 'num', 'num', 'num', 'str'
    @impulses = { @inputs[1]\unwrap! }

  light = (set, active) ->
    set = if set then 'S' else ' '
    active = if active then 'A' else ' '
    color switch set .. active
      when '  ' then 0, 0
      when ' A' then 1, 1
      when 'S ' then 1, 0
      when 'SA' then 3, 1
  display: (i, active) =>
    port, _, start, chan = @unwrap_inputs!
    port\send 'note-on', chan, (start + i), light @steps[i+1], active

  tick: (first) =>
    port, curr_i, start, chan, steps = @unwrap_inputs!

    if first or @inputs[5]\dirty!
      while steps > #@steps
        table.insert @steps, false
      while steps < #@steps
        table.remove @steps

    curr_i = curr_i % #@steps

    for msg in port\receive!
      if msg.status == 'note-on' and msg.chan == chan
        rel_i = msg.a - start
        if rel_i >= 0 and rel_i < #@steps
          @steps[rel_i+1] = not @steps[rel_i+1]
          @display rel_i, rel_i == curr_i

    if @inputs[2]\dirty!
      prev_i = (curr_i - 1) % #@steps

      @display curr_i, true
      @display prev_i, false

      @out\set @steps[curr_i+1]

{
  'gate-seq': gate_seq
  'cc-seq': cc_seq
}
