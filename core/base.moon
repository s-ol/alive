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
  new: (head, @tag) =>
    @registry = @tag.registry -- @TODO: remove
    @patch head

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
  @get_or_create: (ActionType, head, tag) ->
    last = tag\last!
    compatible = last and
                 (last.__class == ActionType) and
                 (last\patch head) and
                 last

    L\trace if compatible
      "reusing #{last} for #{tag} <#{ActionType.__name} #{head}>"
    else if last
      "replacing #{last} with new #{tag} <#{ActionType.__name} #{head}>"
    else
      "initializing #{tag} <#{ActionType.__name} #{head}>"

    if compatible
      tag\keep compatible
      compatible
    else
      last\destroy! if last
      with next = ActionType head, tag
        tag\replace next

  __tostring: => "<#{@@__name} #{@head}>"
  __inherited: (cls) => cls.__base.__tostring = @__tostring

class FnDef
  new: (@params, @body, @scope) =>

  __tostring: =>
    table.concat [p\stringify! for p in *@params], ' '

:Op, :Action, :FnDef
