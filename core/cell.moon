import Const from require 'core.const'
import op_invoke, fn_invoke from require 'core.invoke'

class Cell
-- common
  new: (@tag, @children, @white) =>
    if not @white
      @white = ['' for i=1,#@children+1]

  head: => @children[1]
  tail: => [c for c in *@children[2,]]

  destroy: =>

-- AST interface
  eval: (scope, registry) =>
    head = @head!\eval scope, registry
    Action = switch head.type
      when 'opdef'
        -- scope\get 'op-invoke'
        op_invoke
      when 'fndef'
        -- scope\get 'fn-invoke'
        fn_invoke
      when 'builtin'
        head\getc!
      else
        error "cannot evaluate expr with head #{head}"

    action = Action\get_or_create head, @tag, registry
    @tag or= action.tag
    action\eval scope, @tail!

  quote: (scope, registry) =>
    children = [child\quote scope, registry for child in *@children]
    with cell = Cell nil, children, @white
      cell.tag = registry\register cell, @tag
      @tag = cell.tag -- for writing back to file

  clone: (prefix) =>
    tag = Const.sym prefix\getc! .. '.' .. @tag\getc!
    children = [child\clone prefix for child in *@children]
    Cell tag, children, @white

  stringify: (depth=-1) =>
    buf = ''
    buf ..= if depth > 0 then '' else @white[0]
    if depth == 0
      buf ..= '...'
    else
      for i, child in ipairs @children
        buf ..= child\stringify depth - 1
        buf ..= if depth > 0 then ' ' else @white[i]

      if depth > 0
        buf = buf\sub 1, #buf - 1

    tag = if @tag then "[#{@tag\stringify!}]" else ''
    '(' .. tag .. buf .. ')'

-- static
  __tostring: => @stringify 2

  parse_args = (tag, parts) ->
    if not parts
      parts, tag = tag, nil

    children, white = {}, { [0]: parts[1] }

    for i = 2,#parts,2
      children[i/2] = parts[i]
      white[i/2] = parts[i+1]

    tag, children, white
  @parse: (...) =>
    tag, children, white = parse_args ...
    @ tag, children, white

class RootCell extends Cell
  head: => Const.sym 'do'
  tail: => @children

  stringify: =>
    buf = ''
    buf ..= @white[0]

    for i, child in ipairs @children
      buf ..= child\stringify!
      buf ..= @white[i]

    buf

  @parse: (...) =>
    @__parent.parse @, (Const.num 0), ...

:Cell, :RootCell
