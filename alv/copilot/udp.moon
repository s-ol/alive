import udp from require 'socket'
import encode, decode from require 'dkjson'
import fn_invoke, op_invoke from require 'alv.invoke'

encode_res = (copilot) =>
  return unless @

  {
    metatype: @metatype
    value: @value
    updated: @updated
    type: tostring @type
  }

class UDPServer
  new: (@copilot) =>
    @sock = udp!
    @sock\settimeout 0
    assert @sock\setsockname '0.0.0.0', 37123

  tick: =>
    while true
      msg, ip, port = @sock\receivefrom!
      break unless msg

      client = { :ip, :port }
      res = if msg = decode msg
        @handle msg, client
      else
        error: 'invalid message'
      @sock\sendto (encode res), ip, port

  handle: (msg, client) =>
    res = { id: msg.id }
    switch msg.type
      when 'tick'
        res.tick = @copilot.T
      when 'modules'
        res.modules = [name for name in pairs @copilot.last_modules]
      when 'info'
        res.tag = msg.tag
        res.module = msg.module or '__root'
        mod = @copilot.last_modules[res.module]
        builtin = mod.registry\last msg.tag
        if builtin and builtin.__class.__name ~= 'DummyReg'
          res.head_meta = builtin.head.meta
          res.result = encode_res builtin.node.result
          res.kind = switch builtin.__class
            when op_invoke then 'op'
            when fn_invoke then 'fn'
            else 'builtin'
        else
          res.error = 'not_registered'
      when 'state'
        res.tag = msg.tag
        res.module = msg.module or '__root'
        mod = @copilot.last_modules[res.module]
        builtin = mod.registry\last msg.tag
        if builtin and builtin.__class.__name ~= 'DummyReg'
          res.value = encode_res builtin.node.result, @copilot
          res.state = if builtin.op then builtin.op.state
        else
          res.error = 'not_registered'
      else
        res.error = 'unknown_type'
    return res

{
  :UDPServer
}
