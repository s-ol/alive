----
-- File watcher and runtime entrypoint.
--
-- @classmod Copilot
lfs = require 'lfs'
import Scope from require 'alv.scope'
import FSModule from require 'alv.module'
import Error from require 'alv.error'
import RTNode from require 'alv.rtnode'
import Constant from require 'alv.result'

parse_args = (args, out={ 'udp-server': false }) ->
  local key
  for a in *args
    if key
      out[key] = a
      key = nil
    else if match = a\match '^%-%-(.*)'
      if 'boolean' == type out[match]
        out[match] = true
      else
        key = match
    else
      table.insert out, a
  assert not key, "value for option '--#{key}' missing!"
  out

export COPILOT

class Copilot
--- static functions
-- @section static

  --- create a new Copilot.
  -- @classmethod
  -- @tparam table args
  new: (@args={}) =>
    @T = 0
    @last_modification = 0
    @last_modules = {}
    @open @args[1] if @args[1]

    if @args['udp-server']
      import UDPServer from require 'alv.copilot.udp'
      @adapter = UDPServer @

--- members
-- @section members

  --- current tick
  -- @tfield number T

  --- change the running script.
  -- @tparam string file
  open: (file) =>
    assert not COPILOT, "another Copilot is already running!"
    COPILOT = @

    if old = @last_modules.__root
      old\destroy!

    @active_modules = nil
    @last_modules.__root = nil

    @last_modules.__root = FSModule file
    @active_module = @last_modules.__root

    COPILOT = nil

  --- require a module.
  -- @tparam string name
  -- @treturn RTNode root
  require: (name) =>
    Error.wrap "loading module '#{name}'", ->
      ok, lua = pcall require, "alv-lib.#{name}"
      if ok
        RTNode result: Constant.wrap lua
      elseif not lua\match "not found"
        error lua
      else
        assert @modules, "no current eval cycle?"
        if mod = @modules[name]
          mod.root\make_ref!
        else
          last = @active_module
          prefix = if b = last.file\match'(.*)/[^/]*$' then b .. '/' else ''
          mod = @last_modules[name] or FSModule "#{prefix}#{name}.alv"
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
    @adapter\tick! if @adapter

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

    @eval dirty

  --- try to re-evaluate in response to module changes.
  eval: (dirty) =>
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
  :parse_args
  :Copilot
}
