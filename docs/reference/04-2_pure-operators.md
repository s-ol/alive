The semantics of each operator with regard to its input and output *result
kinds* vary. However there is a large set of operators that share common
semantics. These Operators are called *Pure Operator*s and identified as such
in documentation and reference.

*Pure Op*s only change when any of their inputs change and are often
equivalent to a pure mathematical function. The inputs of a *Pure Op* can be
mixed between all kinds of results, subject to the following rules:

- If any of the inputs is a !-stream, the output is also an !-stream and will
  only fire when the input stream does. All other inputs will be sampled at
  that moment. At most one !-stream is allowed as an input.
- Otherwise, if there are one more ~-streams in the inputs, the output will
  also be a ~-stream and will be updated whenever any of the inputs changes.
- Otherwise the output is a constant.

The input and output *types* are defined by the concrete Op.

As an example, let's consider [math/+][]:

    (import* math time)

    (trace (+ 1 2 3))
    #((+ num= num= num=) -> num=
      trace (+ 1 2 3): <num= 6>)

    (trace (+ 1 2 (lfo 2)))
    #((+ num= num= num~) -> num~
      trace (+ 1 2 (lfo 2)): <num~ 4.0>
      trace (+ 1 2 (lfo 2)): <num~ 3.9882585630406>)

    (trace (+ 1 2 (every 1 3)))
    #((+ num= num= num!) -> num!
      trace (+ 1 2 (every 2 3)): <num! 6>
      trace (+ 1 2 (every 2 3)): <num! 6>)

    (trace (+ 1 (lfo 2) (every 1 3)))
    #((+ num= num~ num!) -> num!
      trace (+ 1 (lfo 2) (every 2 3)): <num! 4.9950529446967>
      trace (+ 1 (lfo 2) (every 2 3)): <num! 4.9950529446967>)

Sometimes a *Pure Op* will require additional constraints on the *kinds* of
some of its inputs. These will be specified in the documentation.
