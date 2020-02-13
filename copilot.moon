lfs = require 'lfs'
import parse, globals, Scope, Registry from require 'core'

slurp = (file) ->
  file = io.open file, 'r'
  with file\read '*all'
    file\close!

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

class Copilot
  new: (@file) =>
    @registry = Registry!

    @last_modification = 0

    mode = lfs.attributes @file, 'mode'
    if mode != 'file'
      error "not a file: #{@file}"

  patch: =>
    ast, err = parse slurp @file

    if not ast
      L\error "error parsing: #{err}"
      return

    scope = Scope ast, globals
    ok, err = pcall (@registry\wrap ast\eval), scope, @registry
    if not ok
      L\error "error evaluating: #{err}"
      return

    @root = err

    spit @file, ast\stringify!

  update: (dt) =>
    @poll!

    if @root
      @root\update dt

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
