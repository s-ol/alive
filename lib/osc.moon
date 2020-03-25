import Op, ValueStream, Input, val from require 'core.base'
import pack from require 'osc'
import dns, udp from require 'socket'

unpack or= table.unpack

connect = ValueStream.meta
  meta:
    name: 'connect'
    summary: "Create a UDP remote."
    examples: { '(osc/connect host port)' }

  value: class extends Op
    pattern = val.str + val.num
    setup: (inputs) =>
      @out or= ValueStream 'udp/socket'
      { host, port } = pattern\match inputs
      super
        host: Input.hot host
        port: Input.hot port

    tick: =>
      { :host, :port } = @unwrap_all!
      ip = dns.toip host

      @out\set with sock = udp!
        \setpeername ip, port

send = ValueStream.meta
  meta:
    name: 'send'
    summary: "Send a value via OSC."
    examples: { '(osc/send [socket] path val)' }
    description: "sends a message only when `val` is dirty."

  value: class extends Op
    pattern = -val['udp/socket'] + val.str + val!
    setup: (inputs, scope) =>
      { socket, path, value } = pattern\match inputs
      super
        socket: Input.cold socket or scope\get '*sock*'
        path:   Input.cold path
        value:  Input.hot value

    tick: =>
      { :socket, :path, :value } = @unwrap_all!
      msg = pack path, if 'table' == type value then unpack value else value
      socket\send msg

send_state = ValueStream.meta
  meta:
    name: 'send'
    summary: "Synchronize a value via OSC."
    examples: { '(osc/send! [socket] path val)' }
    description: "sends a message whenever any parameter is dirty."

  value: class extends Op
    pattern = -val['udp/socket'] + val.str + val!
    setup: (inputs, scope) =>
      { socket, path, value } = pattern\match inputs
      super
        socket: Input.hot socket or scope\get '*sock*'
        path:   Input.hot path
        value:  Input.hot value

    tick: =>
      { :socket, :path, :value } = @unwrap_all!
      msg = pack path, value
      socket\send msg

{
  :connect
  :send
  'send!': send_state
}
