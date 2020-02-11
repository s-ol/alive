import Const from require 'core.const'
import op_invoke, fn_invoke from require 'core.invoke'
import Tag from require 'core.registry'

class Cell
-- common
  new: (@tag, @children, @white) =>
    if not @white
      @white = ['' for i=1,#@children+1]

    if not @tag
      @tag = Tag.blank!

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
        print head
        for k,v in pairs head
          print k,v
          print head.__class.__name
        error "cannot evaluate expr with head #{head}"

    @tag.registry = registry
    action = Action\get_or_create head, @tag
    action\eval scope, @tail!

  quote: (scope, registry) =>
    children = [child\quote scope, registry for child in *@children]
    Cell @tag, children, @white

  clone: (parent) =>
    tag = @tag\clone parent
    children = [child\clone parent for child in *@children]
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
        buf = buf\sub 1, #b@uf - 1

    '(' .. @tag\stringify! .. buf .. ')'

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
    @__parent.parse @, (Tag\parse '0'), ...

:Cell, :RootCell
