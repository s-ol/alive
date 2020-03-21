if _VERSION == 'Lua 5.1'
  package.path ..= ';./?/init.lua'
  package.moonpath ..= ';./?/init.moon'

  export assert
  assert = (a, msg, ...) ->
    if not a
      error msg
    a, msg, ...

-- run from CLI
import Logger from require 'logger'
import Copilot from require 'copilot'
import sleep from require 'system'

arguments, key = {}
for a in *arg
  if match = a\match '^%-%-(.*)'
    key = match
    arguments[key] = true
  elseif key
    arguments[key] = a
    key = nil
  else
    table.insert arguments, a

Logger.init arguments.log

assert arguments[1], "no filename given"
copilot = Copilot arguments[1]

while true
  copilot\tick!
  sleep 1 / 1000
