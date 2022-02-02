import TestPilot from require 'spec.test_setup'
import T, Array, Constant from require 'alv'

describe_both = (fn) ->
  describe "math", ->
    test = TestPilot '', '(import* testing math)\n'
    fn!

  describe "math-simple", ->
    test = TestPilot '', '(import* testing math-simple)\n'
    fn!

describe_both ->
  describe "add, sub, mul, div, pow, mod", ->
    it "are aliased as +-*/^%", ->
      COPILOT\eval_once '
        (expect= + add)
        (expect= - sub)
        (expect= * mul)
        (expect= / div)
        (expect= ^ pow)
        (expect= % mod)
      '

    it "are sane", ->
      COPILOT\eval_once '
        (expect= 2 (+ 1 1))
        (expect= 6 (+ 2 3 0 1))

        (expect= -5 (- 2 7))
        (expect= 0 (- 10 4 3 2 1 0))
        (expect= -10 (- 10))

        (expect= 1 (* 1 1))
        (expect= -2 (* -1 2))
        (expect= 14 (* 4 0.5 7))

        (expect= 1 (/ 4 4))
        (expect= -2 (/ -10 5))
        (expect= 3 (/ -30 -10))

        (expect= 1024 (^ 2 10))
        (expect= 0.25 (^ 4 -1))
        (expect= 1 (^ 999 0))

        (expect= 4 (% 10 6))
        (expect= 3 (% -2 5))
        (expect= -2 (% -2 -5))
      '

  describe "trigonometric functions and constants", ->
    COPILOT\eval_once '
      (expect= tau (* pi 2))

      #(darn you fp accuracy!
        (expect= 0.5 (asin (sin 0.5)))
        (expect= 0.5 (acos (cos 0.5)))
        ...)
      '

  it "min, max, clamp, huge", ->
    COPILOT\eval_once '
      (expect= 0 (min 0 1 2))
      (expect= 2 (max 0 1 2))

      (expect= -2 (clamp -2 3.5 -4))
      (expect= -1 (clamp -2 3.5 -1))
      (expect= 0 (clamp -2 3.5 0))
      (expect= 1 (clamp -2 3.5 1))
      (expect= 3.5 (clamp -2 3.5 4))

      (expect= (- huge) (min 0 1 -123456789 (- huge)))
      (expect= huge (max 0 1 123456789 huge))
    '

  it "inc, dec", ->
    COPILOT\eval_once '
      (expect= 1 (inc 0))
      (expect= -1 (dec 0))
      (expect= 3 (inc (inc 1)))
      (expect= -1 (dec (dec 1)))
      (expect= 0 (inc (dec 0)) (dec (inc 0)))
    '

describe "math", ->
  test = TestPilot '', '(import* testing math)\n'

  describe "add, sub, mul, div, pow, mod", ->
    it "handle scalar/vector", ->
      COPILOT\eval_once '
        (expect= (array 3 4 5)
          (+ 1 (array 1 2 3) 1))

        (expect= (array 0 1 2)
          (- (array 1 2 3) 1))

        (expect= (array 3 6 9)
          (* 3 (array 1 2 3)))
        (expect= (array 3 6 9)
          (* (array 1 2 3) 3))

        (expect= (array 12 9 4)
          (/ 36 (array 3 4 9)))

        (expect= (array 9 16 25)
          (^ (array 3 4 5) 2))
        (expect= (array 1 2 4 8)
          (^ 2 (array 0 1 2 3)))

        (expect= (array 3 0 1)
          (% (array 3 4 5) 4))
      '

    it "handle vector/vector and matrix/matrix", ->
      COPILOT\eval_once '
        (expect= (array 5 7 9)
          (+ (array 1 2 3)
             (array 4 5 6)))

        (expect= (array (array 11 12)
                        (array 13 14))
          (+
            (array (array 1 2)
                   (array 3 4))
            5
            5))

        (expect= (array 2 0 -2)
          (- (array 3 2 1)
             (array 1 2 3)))

        (expect= (array 1 -2 -3)
          (- (array -1 2 3)))
      '

      err = assert.has.error ->
        COPILOT\eval_once '
          (+ (array 1 2 3)
             (array 1 2))'

      err = assert.has.error ->
        COPILOT\eval_once '
          (+ (array (array 1 2) (array 1 2))
             (array 1 2))'

      err = assert.has.error ->
        COPILOT\eval_once '
          (- (array 1 2 3)
             (array 1 2))'

      err = assert.has.error ->
        COPILOT\eval_once '
          (- (array (array 1 2) (array 1 2))
             (array 1 2))'

  describe "mul", ->
    it "handles scalars and matrices", ->
      with COPILOT\eval_once '
          (* 3
             (array
               (array 1 2)
               (array 4 5)))'
        assert.is.true \is_const!
        assert.is.equal '<num[2][2]= [[3 6] [12 15]]>', tostring .result

      with COPILOT\eval_once '
          (* (array
               (array 1 2)
               (array 4 5))
             3)'
        assert.is.true \is_const!
        assert.is.equal '<num[2][2]= [[3 6] [12 15]]>', tostring .result

    it "handles vectors and matrices", ->
      with COPILOT\eval_once '
          (*
            (array (array 1 0 0)
                   (array 0 1 0)
                   (array 0 0 1))
            (array 4 5 6))'
        assert.is.true \is_const!
        assert.is.equal '<num[3]= [4 5 6]>', tostring .result

      with COPILOT\eval_once '
          (*
            (array (array 1 0 0)
                   (array 0 1 0)
                   (array 3 2 1))
            (array 4 5 1))'
        assert.is.true \is_const!
        assert.is.equal '<num[3]= [4 5 23]>', tostring .result

    it "handles matrices", ->
      with COPILOT\eval_once '
          (*
            (array (array 1 2 3)
                   (array 4 5 6))
            (array (array 10 11)
                   (array 20 21)
                   (array 30 31)))'
        assert.is.true \is_const!
        assert.is.equal '<num[2][2]= [[140 146] [320 335]]>', tostring .result

    it "handles everything mixed", ->
      with COPILOT\eval_once '
          (*
            (array (array 1 2 3)
                   (array 4 5 6))
            2
            (array (array 10 11)
                   (array 20 21)
                   (array 30 31)))'
        assert.is.true \is_const!
        assert.is.equal '<num[2][2]= [[280 292] [640 670]]>', tostring .result

      with COPILOT\eval_once '
          (*
            (array (array 1 2 3)
                   (array 4 5 6))
            2
            (array (array 10 11)
                   (array 20 21)
                   (array 30 31))
            (array 4 7))'
        assert.is.true \is_const!
        assert.is.equal '<num[2]= [3164 7250]>', tostring .result

    it "errors with wrong sizes (matrix and vector)", ->
      err = assert.has.error -> COPILOT\eval_once '
        (*
          (array (array 1 2 3)
                 (array 4 5 6))
          (array 1 2))'
      -- assert.matches "", err

      err = assert.has.error -> COPILOT\eval_once '
        (*
          (array 1 2 3)
          (array (array 1 2 3)
                 (array 4 5 6)))'
      -- assert.matches "", err

    it "errors with wrong sizes (matrix)", ->
      err = assert.has.error -> COPILOT\eval_once '
        (*
          (array (array 1 2 3)
                 (array 4 5 6))
          (array (array 1 2)
                 (array 4 5)))'
      -- assert.matches "", err

  it "min, max, clamp, huge", ->
    COPILOT\eval_once '
      (expect= (array 3 2 1)
        (min (array 3 4 1) (array 5 2 huge)))
      (expect= (array 5 huge 4)
        (max (array 3 huge 4) (array 5 999 2)))

      (expect= (array -2 -1 0 1 3.5)
        (clamp -2 3.5 (array -4 -1 0 1 4)))

      (expect= 1 (inc 0))
      (expect= -1 (dec 0))
      (expect= 3 (inc (inc 1)))
      (expect= -1 (dec (dec 1)))
      (expect= 0 (inc (dec 0)) (dec (inc 0)))
    '
