version = require 'alv.version'
dom = require 'docs.gen.dom'
import compile from require 'discount'
import opairs from require 'alv.util'

render_meta = (meta) ->
  import p, code from dom
  contents = {}
  if meta.examples
    -- table.insert contents, h4 'signature'
    examples = p table.concat [code e for e in *meta.examples], ' '
    table.insert contents, examples
  if meta.description
    description = compile meta.description\match '^\n*(.+)\n*$'
    table.insert contents, description.body

  contents

-- render a Result to a HTML string
render = (name, result, prefix=nil, index=false) ->
  import div, label, code, ul, li, i, a, pre from dom

  prefix = if prefix then prefix .. "/" else ""
  id = prefix .. name
  typestr = i tostring result.type
  assert result.meta, "#{id} doesn't have any metadata!"
  summary = assert result.meta.summary, "#{id} doesn't have a summary!"

  if result.meta.name != name
    summary = i "alias of ", a (code result.meta.name), href: "##{prefix}#{result.meta.name}"

  if index
    div {
      label (a (code name), href: "##{id}"), ' (', typestr, '): &ensp;&ndash;&ensp;'
      summary
    }
  else
    content = switch tostring result.type
      when 'scope'
        ul for k, node in opairs result!.values
          li render k, node.result, id
      else
        render_meta result.meta

    content.class = 'nest'
    div {
      :id, class: 'def'
      label (a (code name), href: "##{id}"), ' (', typestr, '): &ensp;&ndash;&ensp;'
      summary
      div content
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
  return version.web if ref == '*web*'
  return version.git if ref == '*git*'
  return version.repo if ref == '*repo*'
  return version.release if ref == '*release*'

  mod, sym = ref\match '^(.+)/(.*)$'
  if mod
    abs "reference/module/#{mod}.html##{sym or ref}"
  else
    abs "reference/builtins.html##{sym or ref}"

-- link to a reference
r = (text, ref) ->
  import a, code from dom
  href = link ref or text
  if ref
    a text, :href
  else
    text = text\gsub '/$', ''
    escape = ESCAPE or (i) -> i
    a (code escape text), :href

-- substitute markdown-style reference links
autoref = (str) ->
  str = str\gsub '%[([^%]]-)%]%[%]', r
  str = str\gsub '%[([^%]]-)%]%[:([^%]]-):%]', r
  str

subnav = do
  split_name = (file) ->
    if href = file\match '^docs/(.*/index.html)$'
      return 'index', href

    href, label = file\match '^docs/(.*/([%d%w-_]+)%.html)$'
    label = (label\match '^[%d-]+_([%w-]+)$') or label
    label = label\gsub '-', ' '
    label, href

  title = (file) ->
    if file == 'docs/guide/index.html'
      return "getting started guide"
    if file == 'docs/reference/index.html'
      return "<code>alv</code> language reference"
    elseif mod = file\match '^docs/reference/module/(.*)%.html$'
      return "<code>#{mod}</code> module reference"
    elseif href = file\match '^docs/(.*/index.html)$'
      error "index page without hardcoded name: #{href}"

    num, label = file\match '/([%d-]+)_([%w%-]+)%.html$'
    if num
      num = num\gsub '%f[%d]0', ''
      num = num\gsub '-', '.'
      label = label\gsub '-', ' '
      "#{num}. #{label}"
    else
      (file\match '/([%w%-]+)%.html$')

  subnav_link = (dir, file) ->
    import span, a, u from dom

    if not file
      return span ''
    
    label, href = split_name file
    label = switch dir
      when 'l'
        "&blacktriangleleft;&ensp;back: #{u label}"
      when 'r'
        "next: #{u label}&ensp;&blacktriangleright;"

    a label, href: abs href

  (all) ->
    assert OUT, "OUT needs to be set"
    import div, nav, h1 from dom

    local c
    for i, src in ipairs all
      if OUT == src
        c = i
        break

    div {
      class: 'subheader'
      h1 (title OUT)
      nav {
        subnav_link 'l', all[c-1]
        subnav_link 'r', all[c+1]
      }
    }

aopts = (href, pat) ->
  {
    href: abs href
    class: if OUT\match pat then 'active'
  }

-- layout and write a doc page
-- opts:
--  - preamble
--  - title
--  - style
--  - body (str or table)
layout = (opts) ->
  import header, footer, nav, div, span, b, code, a, article from dom

  head = header nav {
    span {
      b 'alive'
      ' '
      a (code version.tag), href: version.release
      ' documentation'
    }
    div class: 'grow'
    a 'home', aopts 'index.html', '^docs/index.html$'
    a 'guide', aopts 'guide/index.html', '^docs/guide'
    a 'reference', aopts 'reference/index.html', '^docs/reference'
    a 'internals', aopts 'internals/index.html', '^docs/ldoc'
  }
  body = article opts.body
  title = if opts.title
    "#{opts.title} - alive"
  else
    "alive documentation"
  foot = footer div {
    'alive '
    a (code version.tag), href: version.release
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
  :subnav
}
