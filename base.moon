import is_object from require 'moon'

class Const
  types = { sym: true, scope: true, str: true, num: true, op: true, opdef: true, macro: true }
  new: (@type, @value) =>
    assert types[@type], "invalid Const type: #{@type}"

  get: => @value
  getc: => @value

  __tostring: => "<#{@type}: #{@value}>"

class Op
  new: (@node) =>
    @setup @node\tail!

  patch: (next) =>
    @node = next
    @setup @node\tail!

  update: (dt) =>

  get: => @value
  getc: =>
    print "WARN: stream to constant", debug.traceback!
    @value

  destroy: =>

  __tostring: => "<op: #{@@__name}>"
  __inherited: (cls) =>
        cls.__base.__tostring = @__tostring

{
  :Const
  :Op
}
