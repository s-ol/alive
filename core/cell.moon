----
-- S-Expression Cell, implements the `AST` interface.
--
-- Consists of a head expression and any number of tail expressions (both `AST`
-- nodes), a `Tag`, and optionally the internal whitespace as parsed.
--
-- @classmod Cell
import Value from require 'core.value'
import op_invoke, fn_invoke from require 'core.invoke'
import Tag from require 'core.tag'

local RootCell

class Cell
--- methods
-- @section methods

  -- tag:      the parsed Tag
  -- children: sequence of child AST Nodes
  -- white:    optional sequence of whitespace segments ([0 .. #@children])
  new: (@tag=Tag.blank!, @children, @white) =>
    if not @white
      @white = [' ' for i=1,#@children]
      @white[0] = ''

    assert #@white == #@children, "mismatched whitespace length"

  --- get the head of the cell.
  --
  -- @treturn AST
  head: => @children[1]

  --- get the tail of the cell.
  --
  -- @treturn {AST,...}
  tail: => [c for c in *@children[2,]]

  __tostring: => @stringify 2

--- AST interface
--
-- `Cell` implements the `AST` interface.
-- @section ast

  --- evaluate this Cell.
  --
  -- `\eval`uates the head of the expression, and finds the appropriate
  -- `Action` to invoke:
  --
  -- - if head is an `opdef`, use `invoke.op_invoke`
  -- - if head is a `fndef`, use `invoke.fn_invoke`
  -- - if head is a `builtin`, unwrap it
  --
  -- then calls `\eval_cell` on the `Action`.
  --
  -- @tparam Scope scope the scope to evaluate in
  -- @treturn Result the evaluation result
  eval: (scope) =>
    head = assert @head!, "cannot evaluate expr without head"
    head = (head\eval scope)\const!
    Action = switch head.type
      when 'opdef'
        -- scope\get 'op-invoke'
        op_invoke
      when 'fndef'
        -- scope\get 'fn-invoke'
        fn_invoke
      when 'builtin'
        head\unwrap!
      else
        error "cannot evaluate expr with head #{head}"

    Action\eval_cell scope, @tag, head, @tail!

  --- quote this Cell, preserving its identity.
  --
  -- Recursively quotes children, but preserves identity (i.e, shares the
  -- `Tag`). A quoted Cell may only be 'used' once. If you want to `\eval` a
  -- `Cell` multiple times, use `\clone`.
  --
  -- @treturn Cell quoted
  quote: (scope) =>
    children = [child\quote scope for child in *@children]
    Cell @tag, children, @white

  --- create a clone with its own identity.
  --
  -- creates a clone of this Cell with its own identity by prepending a `parent`
  -- to `@tag` and cloning all child expressoins recursively.
  --
  -- @treturn Cell clone
  clone: (parent) =>
    tag = @tag\clone parent
    children = [child\clone parent for child in *@children]
    Cell tag, children, @white

  --- stringify this Cell.
  --
  -- if `depth` is passed, does not faithfully recreate the original string but
  -- rather create useful debug output.
  --
  -- @tparam[opt] int depth the maximum depth, defaults to infinite
  -- @treturn string the exact string this Cell was parsed from, unless `@tag`
  -- changed
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

    tag = if depth == -1 then @tag\stringify! else ''

    '(' .. tag .. buf .. ')'

--- static functions
-- @section static

  parse_args = (tag, parts) ->
    if not parts
      parts, tag = tag, nil

    children, white = {}, { [0]: parts[1] }

    for i = 2,#parts,2
      children[i/2] = parts[i]
      white[i/2] = parts[i+1]

    tag, children, white
  --- parse a Cell (for parsing with Lpeg).
  --
  -- @tparam[opt] Tag tag
  -- @tparam table parts
  -- @treturn Cell
  parse: (...) =>
    tag, children, white = parse_args ...
    @ tag, children, white

  --- parse a root Cell (for parsing with Lpeg).
  --
  -- Root-Cells are at the root of an ALV document.
  -- They have an implicit head of 'do' and a `[0]` tag.
  --
  -- @tparam table parts
  -- @treturn Cell
  parse_root: (parts) =>
    RootCell.parse RootCell, (Tag\parse '0'), parts

-- @type RootCell
class RootCell extends Cell
  head: => Value.sym 'do'
  tail: => @children

  stringify: =>
    buf = ''
    buf ..= @white[0]

    for i, child in ipairs @children
      buf ..= child\stringify!
      buf ..= @white[i]

    buf

{
  :Cell
  :RootCell
}
