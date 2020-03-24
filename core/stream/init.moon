----
-- `Stream` interface and implementations.
--
-- @see Stream
-- @see ValueStream
-- @see EventStream
-- @see IOStream
--
-- @module stream
import ValueStream from require 'core.stream.value'
import EventStream from require 'core.stream.event'
import IOStream from require 'core.stream.io'

{
  :ValueStream
  :EventStream
  :IOStream
}
