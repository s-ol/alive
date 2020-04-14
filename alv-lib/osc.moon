import Op, ValueStream, Input, val, evt from require 'alv.base'
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
    summary: "Send events via OSC."
    examples: { '(osc/send [socket] path evt)' }
    description: "Sends an OSC message with `evt` as an argument.

- `socket` should be a `udp/socket` value. This argument can be omitted and the
  value be passed as a dynamic definition in `*sock*` instead.
- `path` is the OSC path to send the message to. It should be a string-value.
- `evt` is the argument to send. It should be an event stream."
  value: class extends Op
    pattern = -val['udp/socket'] + val.str + evt!
    setup: (inputs, scope) =>
      { socket, path, value } = pattern\match inputs
      super
        socket: Input.cold socket or scope\get '*sock*'
        path:   Input.cold path
        value:  Input.hot value

    tick: =>
      { :socket, :path, :value } = @unwrap_all!
      for val in *value
        msg = pack path, if 'table' == type val then unpack val else val
        socket\send msg

sync = ValueStream.meta
  meta:
    name: 'sync'
    summary: "Synchronize a value via OSC."
    examples: { '(osc/sync [socket] path val)' }
    description: "sends a message whenever any parameter is dirty."
    description: "Sends an OSC message with `val` as an argument whenever any
of the arguments change.

- `socket` should be a `udp/socket` value. This argument can be omitted and the
  value be passed as a dynamic definition in `*sock*` instead.
- `path` is the OSC path to send the message to. It should be a string-value.
- `val` is the value to Synchronize. It should be a value stream."

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
  :sync
}
