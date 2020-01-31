lfs = require 'lfs'
import program from require 'parsing'

slurp = (file) ->
  file = io.open file, 'r'
  with file\read '*all'
    file\close!

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

class Copilot
  new: (@file, @registry) =>
    @last_modification = 0

    mode = lfs.attributes @file, 'mode'
    if mode != 'file'
      error "not a file: #{@file}"

  patch: =>
    root = assert (program\match slurp @file), "parse error"
    @registry\patch_root root
    spit @file, root\stringify!

  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    if mode != 'file'
      return

    if @last_modification < modification
      print "---"
      ok, err = pcall @patch, @
      if not ok
        print "ERROR: #{err}"

      @last_modification = os.time!

:Copilot
