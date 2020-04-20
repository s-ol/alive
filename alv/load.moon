----
-- Functions for loading strings and files of alive code.
--
-- @module load
import Result from require 'alv.result'
import Builtin from require 'alv.base'
import Scope from require 'alv.scope'
import Error from require 'alv.error'
import program from require 'alv.parsing'
builtin = require 'alv.builtin'

slurp = (file) ->
  file = io.open file, 'r'
  with file\read '*all'
    file\close!

--- Attempt to load alive code from string.
--
-- @tparam string code the code to load
-- @tparam ?string file name of the source file (for error reporting)
-- @treturn Result
-- @treturn AST the parsed and updated AST
loadstring = (code, file='(unnamed)') ->
  Error.wrap "evaluating '#{file}'", ->
    ast = program\match code
    if not ast
      error Error 'syntax', "failed to parse"

    scope = Scope builtin
    result = ast\eval scope
    result, ast

--- Attempt to load alive code from a file.
--
-- @tparam string file filepath of the source file
-- @treturn Result
-- @treturn AST the parsed and updated AST
loadfile = (file) -> loadstring (slurp file), file

{
  :loadstring
  :loadfile
}
