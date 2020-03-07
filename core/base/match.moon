----
-- Utilities for matching `Result` types.
--
-- @module match
unpack or= table.unpack

class Pattern
  new: (opts) =>
    if 'string' == type opts
      splat, const, type, opt = opts\match '^(%*?)(=?)([%w%-%_%/]+)(%??)$'
      assert type, "couldn't parse type pattern '#{opts}'"
      opts = {
        :type
        splat: splat == '*'
        const: const == '='
        opt: opt == '?'
      }

    @type = opts.type
    @const = opts.const
    @opt = opts.opt
    @splat = opts.splat

  matches: (result) =>
    return false unless result

    if @const
      return false unless result\is_const!

    if not result.value
      return @type == 'nil'

    return true if @type == 'any'

    result.value.type == @type

  match: (results) =>
    if @splat
      matched = while @matches results[1]
        table.remove results, 1

      assert @opt or #matched > 0, "expected at least one argument for spread"
      matched
    else
      matches = @matches results[1]
      assert @opt or matches, "couldn't match argument #{results[1]} as #{@}"
      if matches then table.remove results, 1

  __tostring: =>
    str = @type
    str = '*' .. str if @splat
    str = '=' .. str if @const
    str = str .. '?' if @opt
    str

--- match inputs to a argument type definition.
--
-- `pattern` is a string of type entries. Every type entry can be like this:
--
--  - `any` - matches one `Result` and returns it.
--  - `typename` - matches one `Result` of type `typename` and returns it.
--  - `=typename` - matches one eval-time const `Result`s of type `typname` and
--    returns it.
--  - `typename?` - matches what `typename` would match, if possible (greedy).
--    Otherwise returns `nil`.
--  - `*typename` - matches as many `typename` `Result`s as possible (greedy).
--    Throws if there isn't at least one such `Result`. Returns a sequence of
--    `Result`s.
--  - `*typename?` - like `*typename`, except it also matches zero `Result`s.
--  - `*=typename`, `=typename?` and `*=typename?` behave as expected.
--
--  Except for `typename?` and `*typename?`, all entries throw if they cannot
--  match the next `Result` in `inputs`.
--
--  Throws if there are leftover `inputs` after matching all of `pattern`.
--
-- @tparam string pattern the argument type definition
-- @tparam {Result,...} inputs the list of inputs
-- @treturn {Result|{Result,...},...} the inputs as matched against `pattern`
match = (pattern, inputs) ->
  patterns = while pattern
    pat, rest = pattern\match '^([^ ]+) (.*)$'
    pat = pattern unless pat
    pattern = rest
    Pattern pat
  values = [p\match inputs for p in *patterns]
  assert #inputs == 0, "#{#inputs} extra arguments given!"
  values

{
  :Pattern
  :match
}
