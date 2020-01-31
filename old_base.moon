DISP, OP, OUT = {}, {}, {}

class Value
  new: (@value) =>

  __tostring: => "<value: #{@value}>"

class Dispatcher
  new: =>
    @operators = {}

  dispatch: (...) =>
    for op in pairs @operators
      op\dispatch ...
      op\update!

  register: (op, params=true) =>
    @operators[op] = params

  unregister: (op) =>
    @operators[op] = nil

class Op
  new: (opts={}, defaults) =>
    assert defaults, "OP-def needs default arguments"
    for k,v in pairs defaults
      @[k] = opts[k] or v

    @parents = 0
    @setup!

  setup: =>
  destroy: =>
  update: => -- return current value (pure)

  mount: (lastval) =>
    @parents += 1

    if lastval and @parents == 1
      @setup lastval

  unmount: =>
    @parents -= 1
    if @parents == 0
      @destroy!

class Out
  new: (@handle) =>
    @values = {}
    @mapping = {}

  __call: (key, op) =>
    if @mapping[key]
      @mapping[key]\unmount!

    @mapping[key] = op
    @mapping[key]\mount @values[key]

  update: =>
    for key, op in pairs @mapping
      @values[key] = op\update!

    @handle! if @handle

{
  :Value,
  :DISP, :Dispatcher
  :OP,   :Op
  :OUT,  :Out
}
