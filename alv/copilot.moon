----
-- File watcher and CLI entrypoint.
--
-- @classmod Copilot
lfs = require 'lfs'
import Scope from require 'alv.scope'
import Module from require 'alv.module'
import Error from require 'alv.error'
import RTNode from require 'alv.rtnode'
import Constant from require 'alv.result'

export COPILOT

class Copilot
--- static functions
-- @section static

  --- create a new Copilot.
  -- @classmethod
  -- @tparam string file name/path of the alive file to watch and execute
  new: (file) =>
    @T = 0
    @last_modification = 0
    @last_modules = {}
    @open file if file

--- members
-- @section members

  --- current tick
  -- @tfield number T

  --- change the running script.
  -- @tparam string file
  open: (file) =>
    if old = @last_modules.__root
      old\destroy!

    @last_modules.__root = Module file
    @active_module = @last_modules.__root

  --- require a module.
  -- @tparam string name
  -- @treturn RTNode root
  require: (name) =>
    Error.wrap "loading module '#{name}'", ->
      ok, lua = pcall require, "alv-lib.#{name}"
      if ok
        RTNode value: Constant.wrap lua
      else
        assert @modules, "no current eval cycle?"
        if mod = @modules[name]
          mod.root\make_ref!
        else
          last = @active_module
          prefix = @active_module.file\match('(.*)/[^/]*$') .. '/' or ''
          mod = @last_modules[name] or Module "#{prefix}#{name}.alv"
          L\trace "entering module #{mod}"
          @modules[name] = mod
          @active_module = mod
          ok, err = pcall mod\eval
          L\trace "returning to module #{mod}"
          @active_module = last
          if ok
            mod.root
          else
            error err

  --- poll for changes and tick.
  tick: =>
    assert not COPILOT, "another Copilot is already running!"
    return unless @last_modules.__root

    COPILOT = @
    @T += 1

    @poll!

    root = @last_modules.__root
    if root and root.root
      L\set_time 'run'
      ok, error = Error.try "updating", ->
        root.root\poll_io!
        root.root\tick!
      if not ok
        L\print error

    COPILOT = nil

  --- poll all loaded modules for changes.
  --
  -- Call `eval` if there are any, and write changed and newly added modules
  -- back to disk.
  poll: =>
    dirty = {}
    for name, mod in pairs @last_modules
      if mod\poll! > @last_modification
        table.insert dirty, mod

    return if #dirty == 0

    @last_modification = os.time!
    L\set_time 'eval'
    L\print "changes to files: #{table.concat [m.file for m in *dirty], ', '}"

    @modules = { __root: @last_modules.__root }
    ok, err = Error.try "processing changes", @modules.__root\eval

    if not ok
      for name, mod in pairs @modules
        mod\rollback!
      @modules = nil
      L\error err
      return

    for name, mod in pairs @last_modules
      if not @modules[name]
        mod\destroy!

    for name, mod in pairs @modules
      mod\finish!

    @last_modification = os.time!
    @last_modules, @modules = @modules, nil

{
  :Copilot
}
