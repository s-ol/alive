import space, atom, expr, explist, sexpr, nexpr, program from require 'parsing'

describe 'atom parsing', ->
  test 'symbols', ->
    sym = atom\match 'some-toast help'
    assert.is.equal 'some-toast', sym.raw
    assert.is.equal 'some-toast', sym.value
    assert.is.equal 'some-toast', sym\stringify!

  describe 'numbers', ->
    it 'parses ints', ->
      num = atom\match '1234 nope'
      assert.is.equal '1234', num.raw
      assert.is.equal 1234, num.value
      assert.is.equal '1234', num\stringify!

    it 'parses floats', ->
      num = atom\match '0.123 nope'
      assert.is.equal 0.123, num.value
      assert.is.equal '0.123', num\stringify!

      num = atom\match '.123 nope'
      assert.is.equal .123, num.value
      assert.is.equal '.123', num\stringify!

      num = atom\match '0. nope'
      assert.is.equal 0, num.value
      assert.is.equal '0.', num\stringify!

  describe 'strings', ->
    it 'parses double-quote strings', ->
      str = atom\match '"help some stuff!" nope'
      assert.is.equal 'help some stuff!', str.raw
      assert.is.equal 'help some stuff!', str.value
      assert.is.equal '"help some stuff!"', str\stringify!

    it 'parses single-quote strings', ->
      str = atom\match "'help some stuff!' nope"
      assert.is.equal "help some stuff!", str.raw
      assert.is.equal "help some stuff!", str.value
      assert.is.equal "'help some stuff!'", str\stringify!

    it 'handles escapes', ->
      str = atom\match '"string with \\"quote\\"s"'
      assert.is.equal 'string with \\"quote\\"s', str.raw
      assert.is.equal 'string with "quote"s', str.value
      assert.is.equal '"string with \\"quote\\"s"', str\stringify!

test 'whitespace parsing', ->
  assert.is.equal '  ', space\match '  '
  assert.is.equal '\n\t ', space\match '\n\t '

describe 'nexpr parsing', ->
  it 'handles leading whitespace', ->
    node = nexpr\match ' 3\tok-yes'

    assert.is.equal 2, #node
    assert.is.equal 3, node[1].value
    assert.is.equal 'ok-yes', node[2].value

    assert.is.equal ' 3\tok-yes', node\stringify!

  it 'handles trailing whitespace', ->
    node = nexpr\match '3\tok-yes\n'

    assert.is.equal 2, #node
    assert.is.equal 3, node[1].value
    assert.is.equal 'ok-yes', node[2].value

    assert.is.equal '3\tok-yes\n', node\stringify!

  it 'handles whitespace everywhere', ->
    node = nexpr\match ' 3\tok-yes\n'

    assert.is.equal 2, #node
    assert.is.equal 3, node[1].value
    assert.is.equal 'ok-yes', node[2].value

    assert.is.equal ' 3\tok-yes\n', node\stringify!

describe 'sexpr', ->
  test 'basic parsing', ->
    str = '( 3   ok-yes
    "friend" )'
    node = sexpr\match str

    assert.is.equal '(', node.style
    assert.is.equal 3, #node
    assert.is.equal 3, node[1].value
    assert.is.equal 'ok-yes', node[2].value
    assert.is.equal 'friend', node[3].value

    assert.is.equal str, node\stringify!

  test 'tag parsing', ->
    str = '([42]tagged 2)'
    node = sexpr\match str

    assert.is.equal '(', node.style
    assert.is.equal 2, #node
    assert.is.equal 'tagged', node[1].value
    assert.is.equal 2, node[2].value

    assert.is.equal 42, node.tag
    assert.is.equal str, node\stringify!

describe 'resynthesis', ->
  test 'mixed parsing', ->
    str = '( 3   ok-yes
    "friend" )'
    node = program\match str
    assert.is.equal str, node\stringify!

  test 'complex', ->
    str = '
  (osc "/radius" (lfo (cc 14)))

  (osc rot
    (step
      (note "kick")
      (random-rot)
      (random-rot)
      (random-rot)
      (random-rot)
    )
  ) '
    assert.is.equal str, (program\match str)\stringify!
