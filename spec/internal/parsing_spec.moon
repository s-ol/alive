import space, atom, expr, explist, cell, program, comment
  from require 'alv.parsing'
import Constant from require 'alv'
import Logger from require 'alv.logger'
Logger\init 'silent'

verify_parse = (parser, val) ->
  with assert parser\match val
    assert.is.equal val, \stringify!

verify_parse_nope = (parser, val) ->
  with assert parser\match val
    without_nope = val\match '^(.*) nope$'
    assert.is.equal without_nope, \stringify!

describe 'atom parsing', ->
  test 'symbols', ->
    sym = verify_parse_nope atom, 'some-toast nope'
    assert.is.equal (Constant.sym 'some-toast'), sym

  describe 'numbers', ->
    it 'parses ints', ->
      num = verify_parse_nope atom, '1234 nope'
      assert.is.equal (Constant.num 1234), num

    it 'parses floats', ->
      num = verify_parse_nope atom, '0.123 nope'
      assert.is.equal (Constant.num 0.123), num

      num = verify_parse_nope atom, '.123 nope'
      assert.is.equal (Constant.num 0.123), num

      num = verify_parse_nope atom, '0. nope'
      assert.is.equal (Constant.num 0), num

  describe 'strings', ->
    it 'parses double-quote strings', ->
      str = verify_parse_nope atom, '"help some stuff!" nope'
      assert.is.equal (Constant.str 'help some stuff!'), str

    it 'parses single-quote strings', ->
      str = verify_parse_nope atom, "'help some stuff!' nope"
      assert.is.equal (Constant.str "help some stuff!"), str

    it 'handles escapes', ->
      str = verify_parse_nope atom, '"string with \\"quote\\"s and \\\\" nope'
      assert.is.equal (Constant.str 'string with \"quote\"s and \\'), str

      str = verify_parse_nope atom, "'string with \\'quote\\'s and \\\\' nope"
      assert.is.equal (Constant.str "string with \'quote\'s and \\"), str

describe 'Cell', ->
  test 'basic parsing', ->
    node = verify_parse cell, '( 3   ok-yes
                                "friend" )'

    assert.is.equal 3, #node.children
    assert.is.equal (Constant.num 3), node.children[1]
    assert.is.equal (Constant.sym 'ok-yes'), node.children[2]
    assert.is.equal (Constant.str 'friend'), node.children[3]

  test 'tag parsing', ->
    node = verify_parse cell, '([42]tagged 2)'

    assert.is.equal 2, #node.children
    assert.is.equal 42, node.tag.value

  test 'tag parsing with whitespace', ->
    node = verify_parse cell, '([42]
        tagged 2)'

    assert.is.equal 2, #node.children
    assert.is.equal 42, node.tag.value

describe 'RootCell parsing', ->
  describe 'handles whitespace', ->
    verify = (str) ->
      node = verify_parse program, str

      assert.is.equal 2, #node.children
      assert.is.equal (Constant.num 3), node.children[1]
      assert.is.equal (Constant.sym 'ok-yes'), node.children[2]

    it 'at the front of the string', ->
      verify ' 3\tok-yes'

    it 'at the end of the string', ->
      verify ' 3\tok-yes\n'

    it 'everywhere', ->
      verify ' 3\tok-yes\n'

test 'whitespace', ->
  assert.is.equal '  ', space\match '  '
  assert.is.equal '\n\t ', space\match '\n\t '

describe 'comments', ->
  comment = comment / 1
  it 'are parsed', ->
    str = '#(this is a comment)'
    assert.is.equal str, comment\match str

  it 'extend to matching braces', ->
    str = '#(this is a comment #(with nested comments))'
    assert.is.equal str, comment\match str

  it 'can nest', ->
    str = '#(this is a comment (with nested parenthesis))'
    assert.is.equal str, comment\match str

describe 'resynthesis', ->
  test 'mixed parsing', ->
    str = '( 3   ok-yes
    "friend" )'
    node = verify_parse program, str
    assert.is.equal str, node\stringify!

  test 'complex', ->
    str = '
  #(send a CC controlled LFO to /radius)
  (osc "/radius" (lfo (cc 14)))

  (osc rot
    (step
      #(whenever a kick is received...)
      (note "kick")

      #(..cycle through random rotation values)
      (random-rot)
      (random-rot)
      (random-rot)
      (random-rot)
    )
  ) '
    matched = assert.is.truthy verify_parse program, str
    assert.is.equal str, matched\stringify!

  test 'nested tags', ->
    str = '([2]a ([3]b))'
    matched = assert.is.truthy verify_parse program, str
    assert.is.equal str, matched\stringify!
