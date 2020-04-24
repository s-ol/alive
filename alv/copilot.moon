----
-- File watcher and CLI entrypoint.
--
-- @classmod Copilot
lfs = require 'lfs'
import Scope from require 'alv.scope'
import Registry from require 'alv.registry'
import Error from require 'alv.error'
import loadfile from require 'alv.load'

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

export COPILOT

class Copilot
--- static functions
-- @section static

  --- create a new Copilot.
  -- @classmethod
  -- @tparam string file name/path of the alive file to watch and execute
  new: (file) =>
    @T = 0
    @registry = Registry!
    @open file if file

--- members
-- @section members

  --- current tick
  -- @tfield number T

  --- change the running script.
  -- @tparam string file
  open: (file) =>
    mode = lfs.attributes file, 'mode'
    if mode != 'file'
      error "not a file: #{file}"

    @last_modification = 0
    @file = file

  --- poll for changes and tick.
  tick: =>
    assert not COPILOT, "another Copilot is already running!"
    COPILOT = @
    @T += 1

    return unless @file
    @poll!

    if @root
      L\set_time 'run'
      ok, error = Error.try "updating", ->
        @root\tick_io!
        @root\tick!
      if not ok
        L\print error

    COPILOT = nil

  --- poll all loaded modules for changes.
  --
  -- Call `eval` if there are any, and write changed and newly added modules
  -- back to disk.
  poll: =>
    { :mode, :modification } = (lfs.attributes @file) or {}
    if mode != 'file'
      return

    if @last_modification < modification
      L\set_time 'eval'
      L\log "#{@file} changed at #{modification}"
      @eval!
      @last_modification = os.time!

  --- perform an eval-cycle.
  eval: =>
    @registry\begin_eval!
    ok, root, ast = Error.try "running '#{@file}'", loadfile, @file
    if not ok
      L\print root
      @registry\rollback_eval!
      return

    @registry\end_eval!
    @root = root
    spit @file, ast\stringify!

{
  :Copilot
}
