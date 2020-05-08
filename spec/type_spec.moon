require 'spec.test_setup'
import Primitive, Array, Struct from require 'alv'

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

describe 'Array', ->
  vec3 = Array 3, num

  it 'stringifies well', ->
    assert.is.equal 'num[3]', tostring vec3
    assert.is.equal 'my-type[3][24]', tostring Array 24, Array 3, 'my-type'

  it 'implements __eq sensibly', ->
    assert.is.equal vec3, Array 3, num
    assert.not.equal vec3, Array 2, num
    assert.not.equal vec3, Array 3, str

describe 'Struct', ->
  play = Struct { note: str, dur: num }
  abc = Struct { c: num, b: num, a: num }

  it 'stringifies well', ->
    assert.is.equal '{dur: num, note: str}', tostring play
    assert.is.equal '{a: num, b: num, c: num}', tostring abc

  it 'implements __eq sensibly', ->
    assert.is.equal play, Struct { note: str, dur: num }
    assert.not.equal play, Struct { note: str }
    assert.not.equal play, Struct { note: str, dur: str }
    assert.not.equal play, Struct { note: str, dur: num, extra: num }
