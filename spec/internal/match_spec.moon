import const, sig, evt, any from require 'alv.base.match'
import Op, Input from require 'alv.base'
import RTNode, T, Error from require 'alv'

op_with_inputs = (inputs) ->
  with Op!
    \setup inputs if inputs

mk_const = (type, const) ->
  result = T[type]\mk_const true
  RTNode :result, op: op_with_inputs { Input.hot result }

mk_val = (type, const) ->
  result = T[type]\mk_sig true
  RTNode :result, op: op_with_inputs { Input.hot result }

mk_evt = (type, const) ->
  result = T[type]\mk_evt!
  RTNode :result, op: op_with_inputs { Input.hot result }

describe 'sig and evt', ->
  describe 'type-less shorthand', ->
    it 'matches metatype', ->
      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, sig!\match { str }
      assert.is.equal num, sig!\match { num }
      assert.has.error -> const!\match { str }
      assert.has.error -> const!\match { num }
      assert.has.error -> evt!\match { str }
      assert.has.error -> evt!\match { num }
      assert.is.equal str, any!\match { str }
      assert.is.equal num, any!\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.has.error -> sig!\match { str }
      assert.has.error -> sig!\match { num }
      assert.has.error -> const!\match { str }
      assert.has.error -> const!\match { num }
      assert.is.equal str, evt!\match { str }
      assert.is.equal num, evt!\match { num }
      assert.is.equal str, any!\match { str }
      assert.is.equal num, any!\match { num }
      assert.is.equal str, any!\match { str }
      assert.is.equal num, any!\match { num }

      str = mk_const 'str'
      num = mk_const 'num'
      assert.is.equal str, sig!\match { str }
      assert.is.equal num, sig!\match { num }
      assert.is.equal str, const!\match { str }
      assert.is.equal num, const!\match { num }
      assert.has.error -> evt!\match { str }
      assert.has.error -> evt!\match { num }
      assert.is.equal str, any!\match { str }
      assert.is.equal num, any!\match { num }
      assert.is.equal str, any!\match { str }
      assert.is.equal num, any!\match { num }

    it 'can recall the type', ->
      value = sig!!
      event = evt!!
      thing = any!!
      two_equal_values = value + value
      two_equal_events = event + event
      two_equal_things = thing + thing

      str1 = mk_val 'str'
      str2 = mk_val 'str'
      num = mk_val 'num'
      assert.is.same { str1, str2 }, two_equal_values\match { str1, str2 }
      assert.is.same { str2, str1 }, two_equal_values\match { str2, str1 }
      assert.is.same { num, num }, two_equal_values\match { num, num }
      assert.is.same { str1, str2 }, two_equal_things\match { str1, str2 }
      assert.is.same { str2, str1 }, two_equal_things\match { str2, str1 }
      assert.is.same { num, num }, two_equal_things\match { num, num }
      assert.has.error -> two_equal_values\match { str1, num }
      assert.has.error -> two_equal_values\match { num, str2 }
      assert.has.error -> two_equal_things\match { str1, num }
      assert.has.error -> two_equal_things\match { num, str2 }
      assert.has.error -> two_equal_events\match { str1, str2 }

      str1 = mk_evt 'str'
      str2 = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.same { str1, str2 }, two_equal_events\match { str1, str2 }
      assert.is.same { str2, str1 }, two_equal_events\match { str2, str1 }
      assert.is.same { num, num }, two_equal_events\match { num, num }
      assert.is.same { str1, str2 }, two_equal_things\match { str1, str2 }
      assert.is.same { str2, str1 }, two_equal_things\match { str2, str1 }
      assert.is.same { num, num }, two_equal_things\match { num, num }
      assert.has.error -> two_equal_events\match { str1, num }
      assert.has.error -> two_equal_events\match { num, str2 }
      assert.has.error -> two_equal_things\match { str1, num }
      assert.has.error -> two_equal_things\match { num, str2 }
      assert.has.error -> two_equal_values\match { str1, str2 }

    it 'stringifies well', ->
      assert.is.equal 'any=', tostring const!
      assert.is.equal 'any!', tostring evt!
      assert.is.equal 'any~', tostring sig!
      assert.is.equal 'any', tostring any!

  describe 'typed shorthand', ->
    it 'matches by metatype', ->
      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, sig.str\match { str }
      assert.is.equal num, sig.num\match { num }
      assert.has.error -> const.str\match { str }
      assert.has.error -> const.num\match { num }
      assert.has.error -> evt.str\match { str }
      assert.has.error -> evt.num\match { num }
      assert.is.equal str, any.str\match { str }
      assert.is.equal num, any.num\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.has.error -> sig.str\match { str }
      assert.has.error -> sig.num\match { num }
      assert.has.error -> const.str\match { str }
      assert.has.error -> const.num\match { num }
      assert.is.equal str, evt.str\match { str }
      assert.is.equal num, evt.num\match { num }
      assert.is.equal str, any.str\match { str }
      assert.is.equal num, any.num\match { num }

      str = mk_const 'str'
      num = mk_const 'num'
      assert.is.equal str, sig.str\match { str }
      assert.is.equal num, sig.num\match { num }
      assert.is.equal str, const.str\match { str }
      assert.is.equal num, const.num\match { num }
      assert.has.error -> evt.str\match { str }
      assert.has.error -> evt.num\match { num }
      assert.is.equal str, any.str\match { str }
      assert.is.equal num, any.num\match { num }

    it 'matches by type', ->
      str = mk_const 'str'
      num = mk_const 'num'
      assert.is.equal str, sig.str\match { str }
      assert.is.equal num, sig.num\match { num }
      assert.is.equal str, const.str\match { str }
      assert.is.equal num, const.num\match { num }
      assert.has.error -> sig.num\match { str }
      assert.has.error -> sig.str\match { num }

      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, sig.str\match { str }
      assert.is.equal num, sig.num\match { num }
      assert.has.error -> const.num\match { str }
      assert.has.error -> const.str\match { num }
      assert.has.error -> sig.num\match { str }
      assert.has.error -> sig.str\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.equal str, evt.str\match { str }
      assert.is.equal num, evt.num\match { num }
      assert.has.error -> const.num\match { str }
      assert.has.error -> const.str\match { num }
      assert.has.error -> evt.num\match { str }
      assert.has.error -> evt.str\match { num }

    it 'stringifies well', ->
      assert.is.equal 'str!', tostring evt.str
      assert.is.equal 'num!', tostring evt.num
      assert.is.equal 'str~', tostring sig.str
      assert.is.equal 'num~', tostring sig.num
      assert.is.equal 'str=', tostring const.str
      assert.is.equal 'num=', tostring const.num

  describe 'predicate shorthand', ->
    sig_str = sig ((typ) -> typ == T.str), "str"
    sig_num = sig ((typ) -> typ == T.num), "num"
    const_str = const ((typ) -> typ == T.str), "str"
    const_num = const ((typ) -> typ == T.num), "num"
    evt_str = evt ((typ) -> typ == T.str), "str"
    evt_num = evt ((typ) -> typ == T.num), "num"
    any_str = any ((typ) -> typ == T.str), "str"
    any_num = any ((typ) -> typ == T.num), "num"

    it 'matches by metatype', ->
      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, sig_str\match { str }
      assert.is.equal num, sig_num\match { num }
      assert.has.error -> const_str\match { str }
      assert.has.error -> const_num\match { num }
      assert.has.error -> evt_str\match { str }
      assert.has.error -> evt_num\match { num }
      assert.is.equal str, any_str\match { str }
      assert.is.equal num, any_num\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.has.error -> sig_str\match { str }
      assert.has.error -> sig_num\match { num }
      assert.has.error -> const_str\match { str }
      assert.has.error -> const_num\match { num }
      assert.is.equal str, evt_str\match { str }
      assert.is.equal num, evt_num\match { num }
      assert.is.equal str, any_str\match { str }
      assert.is.equal num, any_num\match { num }

      str = mk_const 'str'
      num = mk_const 'num'
      assert.is.equal str, sig_str\match { str }
      assert.is.equal num, sig_num\match { num }
      assert.is.equal str, const_str\match { str }
      assert.is.equal num, const_num\match { num }
      assert.has.error -> evt_str\match { str }
      assert.has.error -> evt_num\match { num }
      assert.is.equal str, any_str\match { str }
      assert.is.equal num, any_num\match { num }

    it 'matches by type', ->
      str = mk_const 'str'
      num = mk_const 'num'
      assert.is.equal str, sig_str\match { str }
      assert.is.equal num, sig_num\match { num }
      assert.is.equal str, const_str\match { str }
      assert.is.equal num, const_num\match { num }
      assert.is.equal str, any_str\match { str }
      assert.is.equal num, any_num\match { num }
      assert.has.error -> sig_num\match { str }
      assert.has.error -> sig_str\match { num }

      str = mk_val 'str'
      num = mk_val 'num'
      assert.is.equal str, sig_str\match { str }
      assert.is.equal num, sig_num\match { num }
      assert.has.error -> const_num\match { str }
      assert.has.error -> const_str\match { num }
      assert.has.error -> sig_num\match { str }
      assert.has.error -> sig_str\match { num }

      str = mk_evt 'str'
      num = mk_evt 'num'
      assert.is.equal str, evt_str\match { str }
      assert.is.equal num, evt_num\match { num }
      assert.has.error -> const_num\match { str }
      assert.has.error -> const_str\match { num }
      assert.has.error -> evt_num\match { str }
      assert.has.error -> evt_str\match { num }

      assert.has.error -> any_str\match { num }

describe 'choice', ->
  str = mk_val 'str'
  num = mk_val 'num'
  bool = mk_val 'bool'
  choice = sig.str / sig.num

  it 'matches either type', ->
    assert.is.equal str, choice\match { str }
    assert.is.equal num, choice\match { num }
    assert.has.error -> choice\match { bool }

  it 'can recall the choice', ->
    same = choice!
    assert.is.equal num, same\match { num }

    same = same + same
    assert.is.same { str, str }, same\match { str, str }
    assert.is.same { num, num }, same\match { num, num }
    assert.has.error -> same\match { str, num }
    assert.has.error -> same\match { num, str }
    assert.has.error -> same\match { bool, bool }

  it 'makes inner types recall', ->
    same = any!!
    same = same + same
    assert.is.same { str, str }, same\match { str, str }
    assert.is.same { num, num }, same\match { num, num }
    assert.is.same { bool, bool }, same\match { bool, bool }
    assert.has.error -> same\match { str, num }
    assert.has.error -> same\match { num, str }

  it 'stringifies well', ->
    assert.is.equal '(str~ | num~)', tostring choice

describe 'sequence', ->
  str = mk_val 'str'
  num = mk_val 'num'
  bool = mk_evt 'bool'
  seq = sig.str + sig.num + evt.bool

  it 'matches all types in order', ->
    assert.is.same { str, num, bool }, seq\match { str, num, bool }

  it 'can assign non-numeric keys', ->
    named = seq\named 'str', 'num', 'bool'
    assert.is.same { :str, :num, :bool }, named\match { str, num, bool }
    assert.is.same { str, num, bool }, seq\match { str, num, bool }

  it 'fails if too little arguments', ->
    assert.has.error -> seq\match { str, num }

  it 'fails if too many arguments', ->
    assert.has.error -> seq\match { str, num, bool, bool }

  it 'can handle optional children', ->
    opt = -sig.str + sig.num
    assert.is.same { str, num }, opt\match { str, num }
    assert.is.same { nil, num }, opt\match { num }
    assert.has.error -> opt\match { str, str, num }
    assert.has.error -> opt\match { str, num, num }

  it 'can handle repeat children', ->
    rep = sig.str + sig.num*2
    assert.is.same { str, {num} }, rep\match { str, num }
    assert.is.same { str, {num,num} }, rep\match { str, num, num }
    assert.has.error -> rep\match { str }
    assert.has.error -> rep\match { str, num, num, num }

  it 'stringifies well', ->
    assert.is.equal '(str~ num~ bool!)', tostring seq

describe 'repeat', ->
  str = mk_val 'str'
  num = mk_val 'num'

  times = (n, arg) -> return for i=1,n do arg

  it '*x is [1,x[', ->
    rep = sig.str*3
    assert.has.error -> rep\match (times 0, str)
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 3, str), rep\match (times 3, str)
    assert.has.error -> rep\match (times 4, str)
    assert.has.error -> rep\match (times 3, num)

  it '*0 is [1,[', ->
    rep = sig.str*0
    assert.has.error -> rep\match (times 0, str)
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 20, str), rep\match (times 20, str)
    assert.has.error -> rep\match (times 3, num)

  it '^x is [0,x[', ->
    rep = sig.str^3
    assert.is.same {}, rep\match {}
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 3, str), rep\match (times 3, str)
    assert.has.error -> rep\match (times 4, str)
    assert.has.error -> rep\match (times 3, num)

  it '^0 is [0,[', ->
    rep = sig.str^0
    assert.is.same {}, rep\match {}
    assert.is.same (times 1, str), rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.is.same (times 20, str), rep\match (times 20, str)
    assert.has.error -> rep\match (times 3, num)

  it ':rep(min, max) does anything else', ->
    rep = sig.str\rep 2, 2
    assert.has.error -> rep\match {}
    assert.has.error -> rep\match (times 1, str)
    assert.is.same (times 2, str), rep\match (times 2, str)
    assert.has.error -> rep\match (times 3, str)
    assert.has.error -> rep\match (times 2, num)

  it 'works with complex inner types', ->
    rep = (sig.num + sig.str)\rep 2, 2
    assert.has.error -> rep\match {}
    assert.has.error -> rep\match {num, str}
    assert.has.error -> rep\match {num, num}
    assert.is.same {{num, str}, {num, str}}, rep\match {num, str, num, str}
    assert.has.error -> rep\match {str, str, str, str}
    assert.has.error -> rep\match {num, str, num, str, num, str}

  it 'stringifies well', ->
    assert.is.equal 'str~{1-3}', tostring sig.str*3
    assert.is.equal 'str~{1-*}', tostring sig.str*0
    assert.is.equal 'str~{0-*}', tostring sig.str^0
    assert.is.equal 'str~{2-2}', tostring sig.str\rep 2, 2

describe 'complex nesting', ->
  bang = mk_evt 'bang'
  str = mk_val 'str'
  num = mk_val 'num'
  num_c = mk_const 'num'
  pattern = -evt.bang + sig.num*4 +
            (sig.str + (sig.num / sig.str))\named('key', 'val')^0

  it 'just works', ->
    assert.is.same { bang, { num, num }, {} }, pattern\match { bang, num, num }
    assert.is.same { nil, { num }, { { key: str, val: num },
                                     { key: str, val: str } } },
                   pattern\match { num, str, num, str, str }
    assert.has.error -> pattern\match { num, str }
    assert.has.error -> pattern\match { num_c, str }
    assert.has.error -> pattern\match { bang, num_c, num, num_c, num, num, num }
    assert.has.error -> pattern\match { bang, bang, num }
    assert.has.error -> pattern\match { num, str, num_c, str }
    assert.has.error -> pattern\match { num, str, num, str, mk_val 'bool' }

  it 'stringifies well', ->
    assert.is.equal '(bang!? num~{1-4} (str~ (num~ | str~)){0-*})', tostring pattern

  it 'gives useful error feedback', ->
    msg = "couldn't match arguments (num~ str~ bool~) against pattern #{pattern}"
    err = Error 'argument', msg
    assert.has.error (-> pattern\match { num, str, mk_val 'bool' }), err
