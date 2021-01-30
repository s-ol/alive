import Op, PureOp, Constant, SigStream, Input, T, sig, evt from require 'alv.base'
import new_message, add_item from require 'alv-lib._osc'
import dns, udp from require 'socket'

unpack or= table.unpack

connect = Constant.meta
  meta:
    name: 'connect'
    summary: "Create a UDP remote."
    examples: { '(osc/connect host port)' }

  value: class extends Op
    pattern = sig.str + sig.num
    setup: (inputs) =>
      @out or= SigStream T['udp/socket']
      { host, port } = pattern\match inputs
      super
        host: Input.hot host
        port: Input.hot port

    tick: =>
      { :host, :port } = @unwrap_all!
      ip = dns.toip host

      @out\set with sock = udp!
        \setpeername ip, port

send = Constant.meta
  meta:
    name: 'send'
    summary: "Send an OSC message."
    examples: { '(osc/send [socket] path val…)' }
    description: "Sends an OSC message to `path` with `val…` as arguments.

- `socket` should be a `udp/socket` value. This argument can be omitted and the
  value be passed as a dynamic definition in `*sock*` instead.
- `path` is the OSC path to send the message to. It should be a string-value.
- the arguments can be any type:
  - `num` will be sent as `f`
  - `str` will be sent as `s`
  - `bool` will be sent as `T`/`F`
  - `bang` will be sent as `T`
  - arrays will be unwrapped
  - structs will be sent as a series of key/value tuples

This is a pure op, so between the values at most one !-stream input is allowed."

  value: class extends PureOp
    pattern: (evt! / sig!)^0

    full_pattern = -sig['udp/socket'] + sig.str + (evt! / sig!)^0
    setup: (inputs, scope) =>
      { socket, path, values } = full_pattern\match inputs
      super values, scope, {
        socket: Input.cold socket or scope\get '*sock*'
        path:   Input.cold path
      }

    tick: =>
      args = @unwrap_all!
      { :socket, :path } = args
      msg = new_message path
      for i=1,#args
        add_item msg, @inputs[i]\type!, args[i]
      socket\send msg.pack msg.content

Constant.meta
  meta:
    name: 'osc'
    summary: "OSC integration."

  value:
    :connect
    :send
    :sync
