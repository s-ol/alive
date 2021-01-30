import RTNode from require 'alv'

export require

require = do
  old_require = require
  blacklist = {k, true for k in *{'losc', 'socket', 'system', 'luartmidi'}}
  (mod, ...) ->
    return {} if blacklist[mod]
    old_require mod, ...

get_module = (name) ->
  rtn_or_module = require name
  if rtn_or_module.__class == RTNode
    assert rtn_or_module.result
  else
    rtn_or_module

{
  :get_module
}
