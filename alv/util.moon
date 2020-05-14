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

--- check whether a table is a 'plain' table
is_plain_table = (val) -> (type val) == 'table' and not val.__class

--- recursively copy a value
deep_copy = (val) ->
  if is_plain_table val
    {(deep_copy k), (deep_copy v) for k,v in pairs val}
  else
    val

--- map leaf values in a table
deep_map = (val, fn) ->
  if is_plain_table val
    {k, (deep_map v, fn) for k,v in pairs val}
  else
    fn val

--- yield all leaf values in a table
deep_iter = (table) ->
  for k, v in pairs table
    if is_plain_table v
      deep_iter v
    else
      coroutine.yield v

{
  :opairs
  :ancestor
  :deep_copy
  :deep_map
  :deep_iter
}
