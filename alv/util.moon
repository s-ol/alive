-----
--- General utilities
--
-- @module util

sort = (t, order_fn, only_strings) ->
  with index = [k for k,v in pairs t when (not only_strings) or 'string' == type k]
    table.sort index, order_fn

-- ordered next(t)
onext = (state, key) ->
  state.i += 1
  { :t, :index, :i } = state

  if key = index[i]
    key, t[key]

--- ordered pairs(t).
--
-- @tparam table t table to iterate
-- @tparam function order_fn fn for `table.sort`
-- @tparam ?boolean only_strings whether to exclude non-strings from iteration
opairs = (t, order_fn, only_strings=false) ->
  state = { :t, i: 0, index: sort t, order_fn, only_strings }
  onext, state, nil

--- find the ancestor of a MoonScript class
ancestor = (klass) ->
  assert klass, "cant find the ancestor of nil"
  while klass.__parent
    klass = klass.__parent
  klass

{
  :opairs
  :ancestor
}
