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
    @assert_types 'midi/port', 'num', 'num', 'num', 'num', 'str'
    @impulses = { @inputs[1]\unwrap! }

    if not @out\unwrap!
      @out\set apply_range @inputs[6], 0

  tick: =>
    port, i, start, chan, steps = unpack [i\unwrap! for i in *@inputs]
    port = @inputs[1]\unwrap!
    _, i, start, chan, steps = unpack @inputs

    curr_i = i\unwrap! % #@steps
    changed = false

    for msg in port\receive!
      if msg.status == 'control-change' and msg.chan == chan
        i = msg.a - start
        if i < #@steps
          @steps[i+1] = msg.b
          changed = i == curr_i

    if changed or i\dirty! or start\dirty! or chan\dirty! or steps\diry!
      @out\set apply_range @inputs[6], @steps[curr_i+1]

class gate_seq extends Op
  @doc: "(launctl/gate-seq port i start chan [steps]) - Gate-Sequencer

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
