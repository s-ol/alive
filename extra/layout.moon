-- render an ALV Value to a HTML string
render = (name, value, prefix=nil) ->
  import div, label, code, ul, li, i, a, p from require 'extra.dom'

  id = if prefix then "#{prefix}/#{name}" else name
  type = i value.type

  content = switch value.type
    when 'scope'
      ul for k, result in pairs value!.values
        li render k, result.value, id
    when 'opdef', 'builtin'
      p value!.doc
    when 'num', 'str', 'bool'
      code tostring value!

  div {
    :id, class: 'def'
    label (a (code name), :id, href: "##{id}"), ' (', type, '):'
    div content, class: 'nest'
  }

-- generate a relative link
abs = (page) ->
  assert OUT, "OUT needs to be set"
  relative = assert (OUT\match '^docs/(.*)'), "unexpected output path"
  _, depth = relative\gsub '/', '/'
  up = string.rep '../', depth
  "#{up}#{page}"

-- link to a reference
r = (name, page='') ->
  import a, code from require 'extra.dom'
  a (code name), href: "#{page}##{name}"

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

-- layout and write a doc page
-- opts:
--  - title
--  - body
write = (opts) ->
  import nav, div, span, b, code, i, a, article from require 'extra.dom'

  navigation = nav div {
    span (b 'alive'), ' ', (code 'v0.0'), ' documentation'
    i!
    a 'home', href: abs 'index.html'
    a 'getting started', href: abs 'guide.html'
    a 'reference', href: abs 'reference/index.html'
  }
  body = article opts.body

  assert OUT, "OUT needs to be set"
  spit OUT, "<!DOCTYPE html>
<html>
  <head>
    <title>#{opts.title} - alive docs</title>
    <link rel=\"stylesheet\" href=\"#{abs 'style.css'}\">
    <style>

    </style>
  </head>
  <body>
    #{navigation}
    #{body}
  </body>
</html>"


{
  :r
  :render
  :write
}
