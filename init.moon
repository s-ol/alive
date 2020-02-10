-- run from CLI
import monotime, sleep from require 'system'
import Logger from require 'logger'
import Registry from require 'registry'
import Copilot from require 'copilot'

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

delta = do
  period = 1 / 60
  
  local last
  ->
    if last
      target, current = (last + period), monotime!
      if current > target
        L\warn 'Frame Skipped!'
      else
        sleep target - current

    time = monotime!
    with time - (last or time)
      last = time

env = Registry!
copilot = Copilot arguments[1], env

while true
  dt = delta!

  copilot\poll!
  env\update dt
