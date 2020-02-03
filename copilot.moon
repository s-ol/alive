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
    root = program\match slurp @file

    if not root
      L\error "error parsing"
      return

    ok, err = pcall @registry\retag, root
    if not ok
      L\error "error expanding: #{err}"
      return

    spit @file, root\stringify!

    ok, err = pcall @registry\patch!
    if not ok
      L\error "error patching: #{err}"

  tb = (msg) -> debug.traceback msg, 2
  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    if mode != 'file'
      return

    if @last_modification < modification
      L\log "#{@file} changed at #{modification}"
      L\push @\patch
      @last_modification = os.time!

:Copilot
