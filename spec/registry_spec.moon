import Registry, Tag from require 'alv.registry'
import Logger from require 'alv.logger'
Logger\init 'silent'

mk = ->
  mock destroy: =>

describe 'registry', ->
