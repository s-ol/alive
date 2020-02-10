class Op
-- common
  new: =>
  -- (...) => @setup ...

  get: => @value
  getc: =>
    L\warn "stream #{@} cast to constant"
    @value

-- Value interface
  update: =>

  destroy: =>

-- static
  __tostring: => "<op: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

  spawn: (Opdef, ...) ->
    Opdef ...

class Action
-- common
  new: (head, @tag, @registry) =>
    @patch head

  register: =>
    @tag = @registry\register @, @tag

-- AST interface
  -- * eval args
  -- * perform scope effects
  -- * patch nested exprs
  -- * return runtime-tree value
  eval: (scope, tail) => error "not implemented"

  -- free resources
  destroy: =>

  -- update this instance for :eavl() with new head
  -- if :patch() returns false, this instance is :destroy'ed and recreated instead
  -- must *not* return false when called after :new()
  -- only considered if Action types match
  patch: (head) =>
    if head == @head
      true

    @head = head

-- static
  @get_or_create: (ActionType, head, tag, registry) ->
    last = tag and registry\prev tag
    compatible = last and
                 (last.__class == ActionType) and
                 (last\patch head) and
                 last

    if not compatible
      last\destroy! if last
      compatible = ActionType head, tag, registry

    with compatible
      \register!

  __tostring: => "<action: #{@@__name}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

:Op, :Action
