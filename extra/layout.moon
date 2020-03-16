v = require 'core.version'

-- render an ALV Value to a HTML string
render = (name, value, prefix=nil) ->
  import div, label, code, ul, li, i, a, pre from require 'extra.dom'

  id = if prefix then "#{prefix}/#{name}" else name
  type = i value.type

  content = switch value.type
    when 'scope'
      ul for k, result in opairs value!.values
        li render k, result.value, id
    when 'opdef', 'builtin'
      pre value!.doc
    when 'num', 'str', 'bool'
      code tostring value!

  div {
    :id, class: 'def'
    label (a (code name), href: "##{id}"), ' (', type, '):'
    div content, class: 'nest'
  }

-- generate a relative link
abs = (page) ->
  if BASE
    "#{BASE}#{page}"
  else
    assert OUT, "OUT needs to be set"
    relative = assert (OUT\match '^docs/(.*)'), "unexpected output path"
    _, depth = relative\gsub '/', '/'
    up = string.rep '../', depth
    "#{up}#{page}"

-- generate a link to a reference entry
-- entry is one of
-- builtin-name; mod.name/name; mod.name
link = (ref) ->
  mod, sym = ref\match '^(.+)/(.*)$'
  abs "reference/#{mod or 'index'}.html##{sym or ref}"

-- link to a reference
r = (text, ref) ->
  import a, code from require 'extra.dom'
  href = link ref or text
  if ref
    a text, :href
  else
    text = text\gsub '/$', ''
    a (code text), :href

-- substitute markdown-style reference links
autoref = (str) ->
  str = str\gsub '%[([^%]]-)%]%[%]', r
  str = str\gsub '%[([^%]]-)%]%[:(.-):%]', r
  str

aopts = (href, pat) ->
  {
    href: abs href
    class: if OUT\match "^docs/#{pat}" then 'active'
  }

-- layout and write a doc page
-- opts:
--  - preamble
--  - title
--  - style
--  - body (str or table)
layout = (opts) ->
  import header, footer, nav, div, span, b, code, a, article from require 'extra.dom'

  head = header nav {
    span {
      a 'alive', href: abs 'index.html'
      ' '
      code v.tag
      ' documentation'
    }
    div class: 'grow'
    a 'home', aopts 'index.html', 'index.html$'
    a 'getting started', aopts 'guide.html', 'guide.html$'
    a 'reference', aopts 'reference/index.html', 'reference'
    a 'internals', aopts 'internals/index.html', 'ldoc'
  }
  body = article opts.body
  title = if opts.title
    "#{opts.title} - alive"
  else
    "alive documentation"
  foot = footer div {
    'alive '
    a (code v.tag), href: v.web
    ', generated '
    os.date '!%Y-%m-%d %T'
  }

  "#{opts.preamble or ''}
<!DOCTYPE html>
<html>
  <head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=640\">

    <title>#{title}</title>
    <link rel=\"stylesheet\" href=\"#{opts.style or abs 'style.css'}\">
  </head>
  <body>
    #{head}
    #{body}
    #{foot}
  </body>
</html>"


{
  :autoref
  :render
  :layout
}
