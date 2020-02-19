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

copilot = Copilot arguments[1]

while true
  copilot\tick!
  sleep 1 / 1000
