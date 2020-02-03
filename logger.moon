unpack or= table.unpack

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

  mklog = (max_level) -> 
  new: (level='log') =>
    @level = levels[level] or level
    @prefix = ' '

    for name, level in pairs levels
      @[name] = (first, ...) =>
        return unless @level <= level
        where = debug.traceback nil, 2
        where = where\match '^.*\n%s+([%w:/%.]+): '
        print "[#{where}]#{@prefix}#{first}", ...

    if level == levels.print
      @push = (fn, ...) => fn ...

  push: (fn, ...) =>
    last = @prefix
    @prefix ..= '  '

    res = { pcall fn, ... }

    @prefix = last

    if ok = table.remove res, 1
      unpack res
    else
      error unpack res

  init: (...) ->
    export L
    L = Logger ...

{
  :Logger
}
