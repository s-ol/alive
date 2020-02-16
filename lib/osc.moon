import Stream, Op from require 'core'
import pack, unpack from require 'osc'
import dns, udp from require 'socket'

class out extends Op
  @doc: "(out host port path val) - send a value via OSC"

  new: (...) =>
    super ...

    @@udp or= udp!

  setup: (@host, @port, @path, @value) =>

  update: (dt) =>
    ip = dns.toip @host\unwrap 'str'
    port = @port\unwrap 'num'
    msg = pack (@path\unwrap 'str'), @value\unwrap!
    @@udp\sendto msg, ip, port

{
  :out
}
