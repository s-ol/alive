import Atom, Xpr from require 'ast'

describe 'Xpr', ->
  it 'can be walked', ->
    aa = Xpr { '', (Atom '1', '', 1), '' }
    ab = Xpr { '', (Atom '2', '', 2), '' }
    ac = Xpr { '', (Atom '3', '', 3), '' }
    b = Xpr { '', aa, ' ', ab, '' }

    root = Xpr { '', ac, ' ', b, '' }, 'naked'

    iter = root\walk_sexpr!
    for res in *{ ac, aa, ab, b }
      assert.is.equal res, iter!
    assert.is.nil iter!
