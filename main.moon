lfs = require 'lfs'
sleep = require 'sleep'
import program from require 'parsing'

filename = arg[1]

slurp = (file) ->
  file = io.open file, 'r'
  with file\read '*all'
    file\close!

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

class Runtime
  spawn: (sexpr) =>
    print "spawning [#{sexpr.tag}]"

  patch: (new, old) =>
    -- print "patching [#{new.tag}]"

  destroy: (sexpr) =>
    print "destroying [#{sexpr.tag}]"

runtime = Runtime!

class Registry
  new: =>
    @last_tag = 0
    @map = {}

  spawn: (sexpr) =>
    @last_tag += 1

    sexpr.tag or= @last_tag
    @map[sexpr.tag] = sexpr

    runtime\spawn sexpr
    sexpr.tag

  patch: (sexpr) =>
    old = @map[sexpr.tag]

    if not old
      return @spawn sexpr

    @map[sexpr.tag] = sexpr

    runtime\patch sexpr, old
    sexpr.tag

  patch_root: (root) =>
    seen = {}

    for sexpr in root\walk_sexpr!
      tag = if not sexpr.tag
        @spawn sexpr
      else
        @patch sexpr
      seen[tag] = true

    for tag, expr in pairs @map
      if not seen[tag]
        runtime\destroy expr
        @map[tag] = nil

registry = Registry!
last_modification = 0

while true
  sleep 10

  { :mode, :modification } = (lfs.attributes filename) or {}
  if mode != 'file'
    return

  if last_modification >= modification
    continue

  last_modification = modification

  root = assert (program\match slurp filename), "error parsing"
  registry\patch_root root

  spit filename, root\stringify!
