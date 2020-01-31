require 'moonscript'

MODS = MODS or {}
-- table.insert(MODS, 'base')
-- table.insert(MODS, 'debug')
-- table.insert(MODS, 'math')
-- table.insert(MODS, 'time')

for _,mod in ipairs(MODS) do
 package.loaded[mod] = nil
end
for _,mod in ipairs(MODS) do
  require(mod)
end
for k,v in pairs(require 'base') do
  _G[k] = v
end

function reload()
 package.loaded.boot = nil
 require 'boot'
end
