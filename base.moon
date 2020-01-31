class Const
  new: (@value) =>
  get: => @value
  getc: => @value

  __tostring: => "<const: #{@value}>"

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
