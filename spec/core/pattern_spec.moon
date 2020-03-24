import Pattern, match from require 'core.base.match'
import Result, ValueStream from require 'core'

-- wrap in non-const result
wrap = (value) ->
  with Result :value
    .side_inputs = { 'fake' }

-- wrap in const result
wrap_const = (value) -> Result :value

describe 'Type Pattern', ->
  num = wrap ValueStream.num 1
  str = wrap ValueStream.str 'hello'
  special = wrap ValueStream 'midi/sysex-message'
  c_num = wrap_const ValueStream.num 1
  c_str = wrap_const ValueStream.str 'hello'

  describe 'simple types', ->
    it 'matches self type', ->
      pat = Pattern 'num'
      assert.is.true pat\matches num
      assert.is.true pat\matches c_num
      assert.is.false pat\matches str
      assert.is.false pat\matches c_str
      assert.is.false pat\matches nil

    it 'can contain special symbols', ->
      pat = Pattern 'midi/sysex-message'
      assert.is.true pat\matches special
      assert.is.false pat\matches num
      assert.is.false pat\matches str
      assert.is.false pat\matches nil

    it 'can match \'any\' type', ->
      pat = Pattern 'any'
      assert.is.true pat\matches num
      assert.is.true pat\matches str
      assert.is.true pat\matches special
      assert.is.true pat\matches c_num
      assert.is.true pat\matches c_str
      assert.is.false pat\matches nil

  it 'checks const-ness', ->
    pat = Pattern '=any'
    assert.is.true pat.const
    assert.is.true pat\matches c_num
    assert.is.true pat\matches c_str
    assert.is.false pat\matches num
    assert.is.false pat\matches str
    assert.is.false pat\matches nil

    pat = Pattern '=num'
    assert.is.true pat.const
    assert.is.true pat\matches c_num
    assert.is.false pat\matches c_str
    assert.is.false pat\matches num
    assert.is.false pat\matches str
    assert.is.false pat\matches nil

  describe 'can capture', ->
    it 'matches', ->
      pat = Pattern 'str'
      stream = {str, num}
      assert.is.equal str, pat\match stream
      assert.is.same {num}, stream

    it 'errors if not given', ->
      pat = Pattern 'str'
      stream = {}
      assert.has.error -> pat\match stream

      stream = {num, str}
      assert.has.error -> pat\match stream
      assert.is.same {num, str}, stream

    describe 'optional types', ->
      pat = Pattern 'num?'

      it 'at the end', ->
        stream = {}
        assert.is.false, pat\match stream

      it 'in the middle', ->
        stream = {str}
        assert.is.false, pat\match stream

    describe 'splats', ->
      pat = Pattern '*num'
      it 'parses', ->
        assert.is.true pat.splat
        assert.is.equal 'num', pat.type

      it 'at the end', ->
        stream = {}
        assert.has.error -> pat\match stream
        assert.is.same {}, stream

        stream = {num}
        assert.is.same {num}, pat\match stream
        assert.is.same {}, stream

        stream = {num, num}
        assert.is.same {num, num}, pat\match stream
        assert.is.same {}, stream

      it 'in the middle', ->
        stream = {str}
        assert.has.error -> pat\match stream
        assert.is.same {str}, stream

        stream = {num, str}
        assert.is.same {num}, pat\match stream
        assert.is.same {str}, stream

        stream = {num, num, str}
        assert.is.same {num, num}, pat\match stream
        assert.is.same {str}, stream
 
    describe 'optional splats', ->
      pat = Pattern '*num?'
      it 'parses', ->
        assert.is.true pat.splat
        assert.is.true pat.opt
        assert.is.equal 'num', pat.type

      it 'at the end', ->
        stream = {}
        assert.is.same {}, pat\match stream
        assert.is.same {}, stream

        stream = {num}
        assert.is.same {num}, pat\match stream
        assert.is.same {}, stream

        stream = {num, num}
        assert.is.same {num, num}, pat\match stream
        assert.is.same {}, stream

      it 'in the middle', ->
        stream = {str}
        assert.is.same {}, pat\match stream
        assert.is.same {str}, stream

        stream = {num, str}
        assert.is.same {num}, pat\match stream
        assert.is.same {str}, stream

        stream = {num, num, str}
        assert.is.same {num, num}, pat\match stream
        assert.is.same {str}, stream

describe 'match', ->
  num = wrap ValueStream.num 1
  str = wrap ValueStream.str 'hello'
  c_num = wrap_const ValueStream.num 1
  c_str = wrap_const ValueStream.str 'hello'

  it 'matches lists', ->
    assert.is.same {num, num, str}, match 'num num str', {num, num, str}
    assert.is.same {num, str}, match 'num str', {num, str}
    assert.is.same {c_num, str}, match '=num str', {c_num, str}

  it 'throws type errors', ->
    assert.has.error -> match 'str num str', {num, num, str}
    assert.has.error -> match 'num str num', {num, str}
    assert.has.error -> match '=num str', {num, str}

  it 'throws extra arg errors', ->
    assert.has.error -> match 'num str', {num, str, str}
    assert.has.error -> match {}, {num}
    assert.has.error -> match '*num', {num, num, str}

  it 'matches optional arguments', ->
    assert.is.same {str, num, str}, match 'str num? str', {str, num, str}
    assert.is.same {str, nil, str}, match 'str num? str', {str, str}
    assert.is.same {str, nil}, match 'str num?', {str}

  it 'matches splats', ->
    assert.is.same {{c_str, str, str}, num}, match '*str num', {c_str, str, str, num}
    assert.is.same {c_str, {str, str}}, match 'any? *str', {c_str, str, str}
    assert.has.error -> match '*str num', {num}
    assert.has.error -> match 'any? *str', {str}

  it 'matches optional splats', ->
    assert.is.same {{c_str, str, str}, num}, match '*str? num', {c_str, str, str, num}
    assert.is.same {c_str, {str, str}}, match 'any? *str?', {c_str, str, str}
    assert.is.same {{}, num}, match '*str? num', {num}
    assert.is.same {str, {}}, match 'any? *str?', {str}
