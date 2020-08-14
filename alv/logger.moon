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
    print: 4
    error: 5
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

  --- set the output time (runtime/evaltime).
  -- @tparam string time (`'eval'` or `'run'`)
  set_time: (time) =>
    @stream = switch time
      when 'eval' then io.stderr
      when 'run' then io.stdout
      else error "invalid time '#{time}'"

  --- write out a message (for internal use).
  -- @tparam string message
  put: (message) =>
    @stream\write message, '\n'
    @stream\flush!

--- static functions
-- @section static

  --- create a new Logger.
  -- @classmethod
  -- @tparam string level the log-level to log at.
  new: (level='log') =>
    @level = levels[level] or level
    @prefix = ''
    @set_time 'eval'

    for name, level in pairs levels
      @[name] = (msg) =>
        return unless @level <= level
        @put if @level == levels.debug
          where = debug.traceback '', 2
          "#{msg}\n#{where}"
        else
          tostring msg

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
  @init: (...) =>
    L = @ ...

{
  :Logger
}
