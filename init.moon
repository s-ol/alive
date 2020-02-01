-- run from CLI
import clock_gettime, nanosleep, CLOCK_MONOTONIC from require 'posix.time'
import Registry from require 'registry'
import Copilot from require 'copilot'

delta = do
  gettime = ->
    spec = clock_gettime CLOCK_MONOTONIC
    spec.tv_sec + spec.tv_nsec * 1e-9

  local last, time
  ->
    time = gettime!
    with time - (last or time)
      last = time

env = Registry!
copilot = Copilot arg[1], env

while true
  copilot\poll!

  dt = delta!
  env\update dt

  assert nanosleep tv_sec: 0, tv_nsec: math.floor 1e9 / 60
