import Registry, Tag from require 'core.registry'
import Logger from require 'logger'
Logger.init 'silent'

mk = ->
  mock destroy: =>

describe 'registry', ->
