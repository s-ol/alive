require 'spec.test_setup'
import T, Primitive, Array, Struct from require 'alv'

bool = Primitive 'bool'
num = Primitive 'num'
str = Primitive 'str'

describe 'Primitive', ->
  it 'stringifies well', ->
    assert.is.equal 'bool', tostring bool
    assert.is.equal 'num', tostring num
    assert.is.equal 'str', tostring str

  it 'implements __eq sensibly', ->
    assert.is.equal (Primitive 'bool'), bool
    assert.is.equal (Primitive 'num'), num
    assert.is.equal (Primitive 'str'), str
    assert.not.equal num, bool
    assert.not.equal str, num

  it ':pp pretty-prints values', ->
    assert.is.equal 'true', bool\pp true
    assert.is.equal '4.134', num\pp 4.134
    assert.is.equal '"hello"', str\pp "hello"

  it ':eq compares values', ->
    a, b = {}, {}
    assert.is.true bool\eq true, true
    assert.is.false bool\eq true, false
    assert.is.true num\eq 1, 1
    assert.is.false num\eq 1, -1
    assert.is.true num\eq a, a
    assert.is.false num\eq a, b

describe 'Array', ->
  vec3 = Array 3, num
  str32 = Array 2, Array 3, str
  it 'stringifies well', ->
    assert.is.equal 'num[3]', tostring vec3
    assert.is.equal 'my-type[3][24]', tostring Array 24, Array 3, 'my-type'

  it 'implements __eq sensibly', ->
    assert.is.equal vec3, Array 3, num
    assert.not.equal vec3, Array 2, num
    assert.not.equal vec3, Array 3, str

  it ':pp pretty-prints values', ->
    assert.is.equal '[1 2 3]', vec3\pp { 1, 2, 3 }
    assert.is.equal '[["a" "b" "c"] ["d" "e" "f"]]',
                    str32\pp { {'a', 'b', 'c'}, {'d', 'e', 'f'} }

  it ':eq compares values', ->
    a, b, c = {1, 2, 3}, {1, 2, 3}, {}
    assert.is.true  vec3\eq a, a
    assert.is.true  vec3\eq a, b
    assert.is.false vec3\eq a, {1, 2, 4}
    assert.is.true  vec3\eq {1, 2, c}, {1, 2, c}
    assert.is.false vec3\eq {1, 2, c}, {1, 2, {}}
    assert.is.true  str32\eq { {'a', 'b', 'c'}, {'d', 'e', 'f'} },
                             { {'a', 'b', 'c'}, {'d', 'e', 'f'} }
    assert.is.false str32\eq { {'a', 'b', 'c'}, {'d', 'e', 'f'} },
                             { {'a', 'b', 'c'}, {'d', 'e', 'g'} }

describe 'Struct', ->
  play = Struct { note: str, dur: num }
  abc = Struct { c: num, b: num, a: num }

  it 'stringifies well', ->
    assert.is.equal '{dur: num note: str}', tostring play
    assert.is.equal '{a: num b: num c: num}', tostring abc

  it 'implements __eq sensibly', ->
    assert.is.equal play, Struct { note: str, dur: num }
    assert.not.equal play, Struct { note: str }
    assert.not.equal play, Struct { note: str, dur: str }
    assert.not.equal play, Struct { note: str, dur: num, extra: num }

  it ':pp pretty-prints values', ->
    assert.is.equal '{dur: 0.5 note: "a"}', play\pp { dur: 0.5, note: 'a' }
    assert.is.equal '{a: 1 b: 2 c: 3}', abc\pp { a: 1, b: 2, c: 3 }

  it ':eq compares values', ->
    a, b, c = { dur: 0.5, note: 'a' }, { dur: 0.5, note: 'a' }, {}
    assert.is.true  play\eq a, a
    assert.is.true  play\eq a, b
    assert.is.false play\eq a, { dur: 0.5, note: 'b' }
    assert.is.true  play\eq { dur: 0.5, note: c }, { dur: 0.5, note: c }
    assert.is.false play\eq { dur: 0.5, note: c }, { dur: 0.5, note: {} }

describe 'T', ->
  it 'provides shorthand for Primitives', ->
    assert.is.equal num, T.num
    assert.is.equal str, T.str
    assert.is.equal (Primitive 'midi/evt'), T['midi/evt']

for type in *{num, str, (Array 3, num)}
  describe "#{type}", ->
    describe ':mk_sig', ->
      it 'can create value-less Streams', ->
        stream = type\mk_sig!
        assert.is.equal 'SigStream', stream.__class.__name
        assert.is.equal type, stream.type
        assert.is.nil stream!

      it 'can take an initial value', ->
        stream = type\mk_sig 4
        assert.is.equal 'SigStream', stream.__class.__name
        assert.is.equal type, stream.type
        assert.is.equal 4, stream!

    describe ':mk_const', ->
      it 'takes a value', ->
        stream = type\mk_const 4
        assert.is.equal 'Constant', stream.__class.__name
        assert.is.equal type, stream.type
        assert.is.equal 4, stream!

    describe ':mk_evt', ->
      stream = type\mk_evt!
      assert.is.equal 'EvtStream', stream.__class.__name
      assert.is.equal type, stream.type
