import Registry from require 'registry'
import Const from require 'core'

mk = ->
  mock destroy: =>

describe 'registry', ->
  registry = Registry!

  a, b, c = mk!, mk!, mk!

  it 'registers new items', ->
    assert.is.equal (Const.num 1), registry\register a, nil
    assert.is.equal (Const.num 2), registry\register b, nil

  it 'is empty until stepped', ->
    assert.is.nil registry\prev Const.num 1
    assert.is.nil registry\prev Const.num 2
    assert.is.nil registry\prev Const.num 3

    registry\step!

  it 'memorizes items', ->
    assert.is.equal a, registry\prev Const.num 1
    assert.is.equal b, registry\prev Const.num 2
    assert.is.nil      registry\prev Const.num 3

  it 'destroyes lost items', ->
    assert.is.equal (Const.num 2), registry\register b, Const.num 2
    assert.is.equal (Const.num 3), registry\register c, nil

    assert.is.equal a, registry\prev Const.num 1
    assert.is.equal b, registry\prev Const.num 2
    assert.is.nil      registry\prev Const.num 3

    assert.stub(a.destroy).was.not_called!
    assert.stub(b.destroy).was.not_called!
    assert.stub(c.destroy).was.not_called!

    registry\step!

    assert.stub(a.destroy).was.called_with a
    assert.stub(b.destroy).was.not_called!
    assert.stub(c.destroy).was.not_called!

    assert.is.nil      registry\prev Const.num 1
    assert.is.equal b, registry\prev Const.num 2
    assert.is.equal c, registry\prev Const.num 3

  it 'fills holes', ->
    assert.is.equal (Const.num 1), registry\register a, nil
    assert.is.equal (Const.num 2), registry\register b, Const.num 2
    assert.is.equal (Const.num 3), registry\register c, Const.num 3

    assert.is.nil      registry\prev Const.num 1
    assert.is.equal b, registry\prev Const.num 2
    assert.is.equal c, registry\prev Const.num 3

    registry\step!

    assert.is.equal a, registry\prev Const.num 1
    assert.is.equal b, registry\prev Const.num 2
    assert.is.equal c, registry\prev Const.num 3

