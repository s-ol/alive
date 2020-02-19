import Stream, Op from require 'core'
import pack, unpack from require 'osc'
import dns, udp from require 'socket'

class addr extends Op
  @doc: "(remote host port) - UDP remote definition"

  new: =>
    super 'udp/remote'
    @@udp or= udp!

  setup: (params) =>
    super params
    @assert_types 'str', 'num'

  tick: =>
    host, port = @unwrap_inputs!
    ip = dns.toip host
    @out\set { :ip, :port }

class out extends Op
  @doc: "(out host port path val) - send a value via OSC"

  new: (...) =>
    @@udp or= udp!

  setup: (params) =>
    super params
    assert @inputs[3], "need a value"
    @assert_types 'udp/remote', 'str', @inputs[3].type

  update: (dt) =>
    remote, path, value = @unwrap_inputs!
    msg = pack path, value
    @@udp\sendto msg, ip, port

{
  :addr
  :out
}
