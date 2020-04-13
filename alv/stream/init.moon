----
-- `Stream` interface and implementations.
--
-- @see Stream
-- @see ValueStream
-- @see EventStream
-- @see IOStream
--
-- @module stream
import ValueStream from require 'alv.stream.value'
import EventStream from require 'alv.stream.event'
import IOStream from require 'alv.stream.io'

{
  :ValueStream
  :EventStream
  :IOStream
}
