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
    ast = L\try "error parsing:", parse, slurp @file
    return unless ast

    scope = Scope ast, globals
    root = L\try "error evaluating:", ast\eval, scope, @registry
    return unless root

    @root = root if root
    ast

  tick: =>
    @poll!

    if @root
      L\try "error evaluating:", @registry\wrap_tick @root\tick

  tb = (msg) -> debug.traceback msg, 2
  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    if mode != 'file'
      return

    if @last_modification < modification
      L\log "#{@file} changed at #{modification}"
      ast = L\push @registry\wrap_eval @\patch
      spit @file, ast\stringify! if ast
      @last_modification = os.time!

:Copilot
