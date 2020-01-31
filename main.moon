sleep = require 'sleep'
import Copilot from require 'copilot'

class Environment
  spawn: (sexpr) =>
    print "spawning [#{sexpr.tag}]"

  patch: (new, old) =>
    -- print "patching [#{new.tag}]"

  destroy: (sexpr) =>
    print "destroying [#{sexpr.tag}]"

env = Environment!
copilot = Copilot arg[1], env

while True
  sleep 0.01
  copilot\patch!
