import Value, Scope from require 'core'
import render, layout from require 'extra.layout'
import section, h2, p, ul, li, a, code, r from require 'extra.dom'

export OUT
{ OUT, command } = arg

slurp = (file) ->
  file = io.open file, 'r'
  with file\read '*all'
    file\close!

spit = (file, str) ->
  file = io.open file, 'w'
  file\write str
  file\close!

spit OUT, switch command
  when 'module'
    { _, _, module, name } = arg

    name or= module
    module = Scope.from_table require module

    layout
      title: "#{name} module reference"
      body: section {
        h2 (code name), ' reference'
        ul for key, res in opairs module.values
          li render key, res.value
      }

  when 'reference'
    layout
      title: 'reference'
      body: {
        section {
          id: 'modules'
          h2 a "module index", href: '#modules'
          p "These modules can be imported using #{r 'require'}, #{r 'import'} and " ..
            "#{r 'import*'}."
          ul for file in *arg[3,]
            module = file\match '^lib/(.*)%.moon$'
            li a (code module), href: "#{module}.html"
        }
        section {
          id: 'builtins'
          h2 a "builtins", href: '#builtins'
          p "These definitions are automatically loaded into the global Scope of
            every alive session."
          ul for key, val in opairs require 'core.builtin'
            li render key, Value.wrap val
        }
      }

  when 'markdown'
    import compile from require 'discount'

    { _, _, file } = arg
    contents = slurp file
    require 'discount'

    layout compile contents, 'githubtags', 'fencedcode'

  else
    error "unknown command '#{command}'"
