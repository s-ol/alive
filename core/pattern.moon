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

      assert @opt or #matched > 0, "expected at least one argument for spread!"
      matched
    else
      matches = @matches results[1]
      assert @opt or matches, "couldn't match argument #{results[1]} as type #{@type}!"
      matches and table.remove results, 1

match = (pattern, results) ->
  patterns = while pattern
    pat, rest = pattern\match '^([^ ]+) (.*)$'
    pat = pattern unless pat
    pattern = rest
    Pattern pat
  values = [p\match results for p in *patterns]
  assert #results == 0, "#{#results} extra arguments given!"
  unpack values

{
  :Pattern
  :match
}
