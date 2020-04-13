----
-- Logger implementation.
--
-- @classmod Logger
unpack or= table.unpack

export L
L or= setmetatable {}, __index: => ->

class Logger
  levels = {
    debug: 0
    trace: 1
    log:   2
    warn:  3
    error: 4
    print: 5
    silent: 6
  }

--- members
-- @section members

  --- push an indentation level and execute a function in it.
  -- @tparam function fn the function to execute
  -- @param ... parameters to `fn`
  push: (fn, ...) =>
    last = @prefix
    @prefix ..= '  '

    res = { xpcall fn, debug.traceback, ... }

    @prefix = last

    if ok = table.remove res, 1
      unpack res
    else
      error unpack res

--- static functions
-- @section static

  --- create a new Logger.
  -- @classmethod
  -- @tparam string level the log-level to log at.
  new: (level='log') =>
    @level = levels[level] or level
    @prefix = ''

    for name, level in pairs levels
      @[name] = (first, ...) =>
        return unless @level <= level

        where = debug.traceback '', 2
        if level == levels.error or @level == levels.debug
          print @prefix .. first, ...
          print where
        else
          print @prefix .. first, ...

    if level == levels.print
      @push = (fn, ...) => fn ...

  --- set up the global Logger singleton.
  --
  -- The available log-levels are:
  --
  -- - `'debug'`
  -- - `'trace'`
  -- - `'log'` (the default)
  -- - `'warn'`
  -- - `'error'`
  -- - `'print'`
  -- - `'silent'`
  --
  -- @tparam ?string level the level to initialize the logger at.
  @init: (...) ->
    L = Logger ...

{
  :Logger
}
