import Op from require 'base'
import pack, unpack from require 'osc'
import dns, udp from require 'socket'

class out extends Op
  new: (...) =>
    super ...

    @@udp or= udp!

  setup: (@host, @port, @path, @value) =>

  update: (dt) =>
    L\trace "updating #{@}"
    for p in *{@host, @port, @path, @value}
      L\push p\update, dt

    ip = dns.toip @host\get!
    port = @port\get!
    msg = pack @path\get!, @value\get!
    @@udp\sendto msg, ip, port

{
  :out
}
