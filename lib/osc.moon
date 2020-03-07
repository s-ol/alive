import Op, Input, match from require 'core.base'
import pack from require 'osc'
import dns, udp from require 'socket'

unpack or= table.unpack

class connect extends Op
  @doc: "(osc/connect host port) - UDP remote definition"

  new: => super 'udp/socket'

  setup: (inputs) =>
    { host, port } = match 'str num', inputs
    super
      host: Input.value host
      port: Input.value port

  tick: =>
    { :host, :port } = @unwrap_all!
    ip = dns.toip host

    @out\set with sock = udp!
      \setpeername ip, port

class send extends Op
  @doc: "(osc/send socket path val) - send a value via OSC

sends a message only when val is dirty."

  setup: (inputs) =>
    { socket, path, value } = match 'udp/socket str any', inputs
    super
      socket: Input.cold socket
      path:   Input.cold path
      value:  Input.value value

  tick: =>
    if @inputs.value\dirty!
      { :socket, :path, :value } = @unwrap_all!
      msg = if 'table' == type value
        pack path, unpack value
      else
        pack path, value
      socket\send msg

class send_state extends Op
  @doc: "(osc/send! socket path val) - synchronize a value via OSC

sends a whenever any parameter changes."

  setup: (inputs) =>
    { socket, path, value } = match 'udp/socket str any', inputs
    super
      socket: Input.value socket
      path:   Input.value path
      value:  Input.value value

  tick: =>
    { :socket, :path, :value } = @unwrap_all!
    msg = pack path, value
    socket\send msg

{
  :connect
  :send
  'send!': send_state
}
