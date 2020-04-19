----
-- File watcher and CLI entrypoint.
--
-- @classmod Copilot
lfs = require 'lfs'
import Scope from require 'alv.scope'
import Registry from require 'alv.registry'
import Error from require 'alv.error'
import program from require 'alv.parsing'
globals = Scope.from_table require 'alv.builtin'

slurp = (file) ->
  file = io.open file, 'r'
  with file\read '*all'
    file\close!

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

class Copilot
--- static functions
-- @section static

  --- create a new Copilot.
  -- @classmethod
  -- @tparam string file name/path of the alive file to watch and execute
  new: (file) =>
    @registry = Registry!
    @eval_stream, @run_stream = io.stderr, io.stdout
    @open file if file

  open: (file) =>
    mode = lfs.attributes file, 'mode'
    if mode != 'file'
      error "not a file: #{file}"

    @last_modification = 0
    @file = file

--- members
-- @section members

  --- poll for changes and tick.
  tick: =>
    return unless @file

    @poll!

    if @root
      @registry\begin_tick!
      ok, error = Error.try "updating", ->
        @root\tick_io!
        @root\tick!
      if not ok
        L\print error
      @registry\end_tick!

  eval: =>
    @registry\begin_eval!
    ok, ast = Error.try "parsing '#{@file}'", program\match, slurp @file
    if not (ok and ast)
      L\print ast or Error 'syntax', "failed to parse"
      @registry\rollback_eval!
      return

    scope = Scope globals
    ok, root = Error.try "evaluating '#{@file}'", ast\eval, scope, @registry
    if not ok
      L\print root
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
      L.stream = @eval_stream
      L\log "#{@file} changed at #{modification}"
      @eval!
      L.stream = @run_stream
      @last_modification = os.time!

{
  :Copilot
}
