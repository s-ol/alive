-- late-resolve cyclic dependencies
--
-- this module provides a proxy for resolving values from modules which cannot
-- be loaded due to cyclic dependencies. Instead of
--
-- import Something from require 'alv.somewhere'
-- Something ...
--
-- use
--
-- import somewhere from require 'alv.cycle'
-- somewhere.Something ...
--
-- Make sure cycle:resolve() is called before you access or dereference
-- `somewhere`.

unresolved = {}

resolve = =>
  for name, module in pairs unresolved
    for k, v in pairs require "alv.#{name}"
      module[k] = v

  unresolved = {}

setmetatable {}, __index: (key) =>
  return resolve if key == 'resolve'

  with v = {}
    rawset unresolved, key, v
    rawset @, key, v
