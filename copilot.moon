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

  tick: =>
    @poll!

    if @root
      @registry\begin_tick!
      L\try "error evaluating:", ->
        @root\tick_io!
        @root\tick!
      @registry\end_tick!

  eval: =>
    @registry\begin_eval!
    ast = L\try "error parsing:", parse, slurp @file
    if not ast
      L\error "error parsing"
      @registry\rollback_eval!
      return

    scope = Scope globals
    root = L\try "error evaluating:", ast\eval, scope, @registry
    if not root
      @registry\rollback_eval!
      return

    @registry\end_eval!
    @root = root
    spit @file, ast\stringify!

  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    if mode != 'file'
      return

    if @last_modification < modification
      L\log "#{@file} changed at #{modification}"
      @eval!
      @last_modification = os.time!

{
  :Copilot
}
