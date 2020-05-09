----
-- Language error and traceback.
--
-- @classmod Error

unpack or= table.unpack

class Error
--- members
-- @section members

  --- append a traceback frame.
  --
  -- `where` should denote where the Error occured and fit grammatically to
  -- complete the sentence `"{error} occured while {where}"`
  --
  -- @tparam string where
  add_frame: (where) => @trace ..= "\n  while #{where}"

  __tostring: =>
    str = "#{@kind} error: #{@message}"
    if @detail
      str ..= "\n#{@detail}"
    if @trace
      str ..= @trace
    str

--- static functions
-- @section static

  --- create a new Error.
  --
  -- `kind` should be one of:
  --
  -- - `'reference'`: error concerning symbol resolution
  -- - `'argument'`: error concerning Op argument matching
  -- - `'implementation'`: error in the Lua/MoonScript implementation of alive.
  --   Should not occur in normal operation, and constitutes a bug.
  --
  -- @classmethod
  -- @tparam string kind
  -- @tparam string message
  -- @tparam ?string detail
  new: (@kind, @message, @detail) =>
    @trace = ''

  handler = (err) ->
    if err.__class == Error
      err
    else
      trace = debug.traceback "Lua error below:", 2
      Error 'implementation', err, trace

  --- Wrap function errors in a traceback frame.
  --
  -- Execute `fn(...)`, and turn any error thrown as a result into an
  -- `Error` instance, before re-throwing it.
  --
  -- When `Error` instances are caught, `frame` is added to the traceback.
  -- All other error values are turned into `'implementation'` Errors.
  --
  -- @tparam string frame
  -- @tparam function fn
  @wrap: (frame, fn, ...) ->
    results = { xpcall fn, handler, ... }
    ok = table.remove results, 1
    if ok
      unpack results
    else
      results[1]\add_frame frame if frame
      error results[1]

  --- Capture and wrap function errors in traceback frame.
  --
  -- Execute `fn(...)`, and turn any error thrown as a result into an
  -- `Error` instance, before re-throwing it.
  --
  -- When `Error` instances are caught, `frame` is added to the traceback.
  -- All other error values are turned into `'implementation'` Errors.
  --
  -- @tparam ?string frame
  -- @tparam function fn
  -- @treturn boolean `ok` true if exeuction suceeded without errors
  -- @treturn Error|any `error_or_results` the `Error` instance or results
  @try: (frame, fn, ...) ->
    results = { xpcall fn, handler, ... }
    ok = table.remove results, 1
    if ok
      ok, unpack results
    else
      results[1]\add_frame frame if frame
      ok, unpack results
{
  :Error
}
