-- late-resolve cyclic dependencies
--
-- this module provides a proxy for resolving values from modules which cannot
-- be loaded due to cyclic dependencies. Instead of
--
-- import Something from require 'core.somewhere'
-- Something ...
--
-- use
--
-- import somewhere from require 'core.cycle'
-- somewhere.Something ...
--
-- Make sure cycle:load() is called before you access or dereference
-- `somewhere`.

load = =>
  for name, module in pairs @
    for k, v in pairs require "core.#{name}"
      module[k] = v

setmetatable {}, __index: (key) =>
  return load if key == 'load'

  with v = {}
    rawset @, key, v
