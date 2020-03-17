import Value, Scope from require 'core'
import render, layout, autoref from require 'extra.layout'
import section, h1, h2, p, ul, li, a, code, r from require 'extra.dom'

export OUT, BASE, require
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

    require = do
      old_require = require
      blacklist = {k, true for k in *{'osc', 'socket', 'system', 'luartmidi'}}
      (mod, ...) ->
        return {} if blacklist[mod]
        old_require mod, ...

    name or= module
    module = Scope.from_table require module

    layout
      title: "#{name} reference"
      body: section {
        h2 (code name), ' module reference'
        ul for key, res in opairs module.values
          li render key, res.value
      }

  when 'reference'
    layout
      title: 'reference'
      body: {
        h1 (code 'alive'), " language reference"
        p "This section documents all builtins and modules that are currently
          available in the alive programming language."
        p autoref "If you are new to alive, the [getting started guide][:../guide/:] is
          the recommended place to start. If you are looking for
          information on adding your own module or contributing to alive, check
          out the [developer documentation][:../internals/index/:]."
        section {
          id: 'modules'
          h2 a "module index", href: '#modules'
          p autoref "These modules can be imported using [require][], " ..
            "[import][] and [import*][]."
          ul for file in *arg[3,]
            path = file\match '^lib/(.*)%.moon$'
            name = path\gsub '/', '.'
            li a (code name), href: "#{path}.html"
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

    layout compile (autoref contents), 'githubtags', 'fencedcode'

  when 'ldoc'
    BASE = '$(base)'
    layout
      style: '$(ldoc.css)'
      title: '$(ldoc.title)'
      class: 'ldoc'
      preamble: '
# local iter = ldoc.modules.iter
# local M = ldoc.markup
# local function display_name(item)
#   if item.type == "function" then
#     return item.name:gsub(":new$", "")..item.args
#   else return item.name end
#  end
# local function use_li(ls)
#   if #ls > 1 then return "<li>","</li>" else return "","" end
# end
# local base = module and "../../" or "../"'
      body: {
        class: 'ldoc'
        '
# if ldoc.body then
  $(ldoc.body)
# elseif not module then
# if ldoc.description then
  <h1>$(M(ldoc.description))</h1>
# end
# if ldoc.full_description then
  <p>$(M(ldoc.full_description))</p>
#end

# for kind, mods in ldoc.kinds() do
#   kind = kind:lower()
    <h2>$(kind)</h2>
    <ul>
#   for m in mods() do
      <li>
#       if m.summary then
    		<label><a href="$(kind)/$(m.name).html"><code>$(m.name)</code></a>:</label>
    		<span>$(M(m.summary))</span>
# else
       	<label><a href="$(kind)/$(m.name).html"><code>$(m.name)</code></a></label>
# end
    	</tr>
#   end
    </ul>
# end
# else
  <h1>$(ldoc.module_typename(module):lower()) <code>$(module.name)</code></h1>
  <p>$(M(module.summary, module))</p>
  <p>$(M(module.description, module))</p>

# if module.see then
#   local li,il = use_li(module.see)
    <h3>see also:</h3>
    <ul>
#   for see in iter(module.see) do
      $(li)<a href="$(ldoc.href(see))">$(see.label)</a>$(il)
#   end
    </ul>
# end

# if module.kinds()() then
    <h2>index</h2>
#   for kind, items in module.kinds() do
#     kind = kind:lower()
      <h3 class="indent">$(kind)</h3>
      <ul>
#     for item in items() do
        <li>
          <a href="#$(item.name)"><code>$(display_name(item))</code></a>
          &ensp;&ndash;&ensp;$(M(item.summary))
        </li>
#     end
      </ul>
#   end

    <h2>details</h2>
#   for kind, items in module.kinds() do
#     kind = kind:lower()
      <h3 class="indent">$(kind)</h3>
      <ul>
#     for item in items() do
        <li class="def" id="$(item.name)">
          <label>
            <a href="#$(item.name)"><code>$(display_name(item))</code></a>
          </label>
          &ensp;&ndash;&ensp;$(M(item.summary))
          <div class="nest">
          $(M(item.description))

#         if item.usage then
#           local li,il = use_li(item.usage)
            <h4>usage:</h4>
            <ul>
#           for usage in iter(item.usage) do
              $(li)<pre class="example"><code>$(usage)</code></pre>$(il)
#           end
            </ul>
#         end

#         if item.params and #item.params > 0 then
#           local subnames = module.kinds:type_of(item).subnames
#           if subnames then
              <h4>$(subnames:lower()):</h4>
#           end
            <ul>
#           for parm in iter(item.params) do
#             local param,sublist = item:subparam(parm)
#             for p in iter(param) do
#               local name = item:display_name_of(p)
#               local tp = ldoc.typename(item:type_of_param(p))
#               local def = item:default_of_param(p)
#               local desc = item.params.map[p]
#               local col = desc and desc ~= "" and ":" or ""
                <li>
                  <label>
                    <code>$(name)</code>
#                   if tp ~= "" then
                      ($(tp))$(col)
#                   else
                      $(col)
#                   end
                  </label>
                  $(M(desc,item))
#               if def == true then
                  (<em>optional</em>)
#               elseif def then
                  (<em>default</em> $(def))
#               end
                </li>
#             end
#           end
            </ul>
#         end

#         if item.retgroups then local groups = item.retgroups
            <h4>returns:</h4>
#           for i,group in ldoc.ipairs(groups) do
              <ol>
#             for r in group:iter() do
#               local type, ctypes = item:return_type(r)
#               local rt = ldoc.typename(type)
#               local col = r.text and r.text ~= "" and ":" or ""
                <li>
#                 if rt ~= "" then
                    ($(rt))$(col)
#                 end
                  $(M(r.text,item))
#                 if ctypes then
                    <ul>
#                   for c in ctypes:iter() do
                      <li><span class="parameter">$(c.name)</span>
                      <span class="types">$(ldoc.typename(c.type))</span>
                      $(M(c.comment,item))</li>
#                   end
                    </ul>
#                 end
                </li>
#             end
              </ol>
#             if i < #groups then
               <h4>or</h4>
#             end
#           end
#         end

#         if item.usage then
#           local li,il = use_li(item.usage)
            <h4>usage:</h4>
            <ul>
#           for usage in iter(item.usage) do
              $(li)<pre class="example">$(ldoc.prettify(usage))</pre>$(il)
#           end
            </ul>
#         end
          </div>
      </li>
#     end
  </ul>
#   end
# end
# end
'
      }
  else
    error "unknown command '#{command}'"
