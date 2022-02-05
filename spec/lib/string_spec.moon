import TestPilot from require 'spec.test_setup'
import T, Array from require 'alv'

describe "string", ->
  test = TestPilot '', '(import* testing) (import string)\n'

  describe "str", ->
    it "stringifies all primitives", ->
      COPILOT\eval_once '
        (expect= "hello" (string/str "hello"))
        (expect= "1" (string/str 1))
        (expect= "0.5" (string/str 0.5))
        (expect= "true" (string/str true))
        (expect= "false" (string/str false))
      '

    it "stringifies arrays", ->
      COPILOT\eval_once '
        (expect= "[1 2 3]" (string/str (array 1 2 3)))
        (expect= \'["a" "b" "c"]\' (string/str (array "a" "b" "c")))
      '

    it "stringifies structs", ->
      COPILOT\eval_once '
        (expect= \'{a: 1 b: true c: "hello"}\'
          (string/str (struct "a" 1
                              "b" true
                              "c" "hello")))
      '

    it "stringifies deeply", ->
      COPILOT\eval_once '
        (expect= "{a: {b: [1 2 3]}}"
          (string/str (struct "a" (struct "b" (array 1 2 3)))))
      '

    it "joins multiple arguments", ->
      COPILOT\eval_once '
        (expect= "helloworld" (string/str "hello" "world"))
        (expect= "here is 1 apple" (string/str "here is " 1 " apple"))
        (expect= "this statement is true" (string/str "this statement is " true))
        (expect= "false is a word." (string/str false " is a word."))
      '

    it "is aliased as ..", ->
      COPILOT\eval_once '(expect= string/str string/..)'

  describe "concat", ->
    it "concatenates string-arrays", ->
      COPILOT\eval_once '
        (expect= "hello" (string/concat (array "hello")))
        (expect= "helloworld" (string/concat (array "hello" "world")))
        (expect= "helloobeautifulworld" (string/concat (array "hello" "o" "beautiful" "world")))
      '

    it "takes custom separator", ->
      COPILOT\eval_once '
        (expect= "a, b, c" (string/concat ", " (array "a" "b" "c")))
        (expect= "hello world" (string/concat " " (array "hello" "world")))
        (expect= "hello o beautiful world" (string/concat " " (array "hello" "o" "beautiful" "world")))
      '

  describe "join", ->
    it "concatenates and stringifies", ->
      COPILOT\eval_once '
        (expect= "that is 1 beautiful tree" (string/join " " "that is" 1 "beautiful tree"))
        (expect= "my favorite color is [0.9 0.2 1]" (string/join " " "my favorite color is" (array 0.9 0.2 1)))
        (expect= "i_am_snek" (string/join "_" "i" "am" "snek"))
      '

