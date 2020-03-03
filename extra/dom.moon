-- mmm.dom
-- see https://mmm.s-ol.nu/meta/mmm.dom/

export opairs

-- ordered table iterator, for stable(r) renderers
sort = (t, order_fn, only_strings) ->
  with index = [k for k,v in pairs t when (not only_strings) or 'string' == type k]
    table.sort index, order_fn

-- ordered next(t)
onext = (state, key) ->
  state.i += state.step
  { :t, :index, :i } = state

  if key = index[i]
    key, t[key]

-- ordered pairs(t).
-- order_fn is optional; see table.sort
opairs = (t, order_fn, only_strings=false) ->
  state = { :t, i: 0, step: 1, index: sort t, order_fn, only_strings }
  onext, state, nil

void_tags = { 'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr' }
void_tags = { t,t for t in *void_tags }

element = (element) -> (...) ->
  children = { ... }

  -- attributes are last arguments but mustn't be a ReactiveVar
  attributes = children[#children]
  if 'table' == (type attributes) and not attributes.node
    table.remove children
  else
    attributes = {}

  b = "<#{element}"
  for k,v in opairs attributes, nil, true
    if k == 'style' and 'table' == type v
      tmp = ''
      for kk, vv in opairs v
        tmp ..= "#{kk}: #{vv}; "
      v = tmp
    b ..= " #{k}=\"#{v}\""

  -- if there is only one argument,
  -- children can be in attributes table too
  if #children == 0
    children = attributes

  for i,v in ipairs children
    if 'string' != type v
      print v
      error "wrong type: #{type v}"
    children[i] = '' unless v

  if void_tags[element]
    assert #children == 0, "void tag #{element} cannot have children!"
    b .. ">"
  else
    b ..= ">" ..  table.concat children, ''
    b ..= "</#{element}>"
    b

setmetatable {}, __index: (name) =>
  with val = element name
    @[name] = val
