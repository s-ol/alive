import Op, Value, Input, match from require 'core.base'
import pack from require 'osc'
import dns, udp from require 'socket'

unpack or= table.unpack

connect = Value.meta
  meta:
    name: 'connect'
    summary: "Create a UDP remote."
    examples: { '(osc/connect host port)' }

  value: class extends Op
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

send = Value.meta
  meta:
    name: 'send'
    summary: "Send a value via OSC."
    examples: { '(osc/send socket path val)' }
    description: "sends a message only when `val` is dirty."

  value: class extends Op
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

send_state = Value.meta
  meta:
    name: 'send'
    summary: "Synchronize a value via OSC."
    examples: { '(osc/send! socket path val)' }
    description: "sends a message whenever any parameter is dirty."

  value: class extends Op
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
