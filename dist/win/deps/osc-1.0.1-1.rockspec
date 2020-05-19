package = "osc"
version = "1.0.1-1"
source = {
  url = 'git://github.com/lubyk/osc',
  tag = 'REL-1.0.1',
  dir = 'osc',
}
description = {
  summary = "OpenSoundControl for Lua with some wrappers around lens.Socket.",
  detailed = [[
  Simply packs/unpacks between Lua values and binary strings ready to be sent
  on the network or other transports.

  Uses Ross Bencina oscpack library.
  ]],
  homepage = "http://doc.lubyk.org/osc.html",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, < 5.4",
  "lub >= 1.0.3, < 2.0",
}
build = {
  type = 'builtin',
  modules = {
    -- Plain Lua files
    ['osc'            ] = 'osc/init.lua',
    ['osc.Client'     ] = 'osc/Client.lua',
    ['osc.Server'     ] = 'osc/Server.lua',
    -- C module
    ['osc.core'       ] = {
      defines = {'OSC_HOST_LITTLE_ENDIAN'},
      sources = {
        'src/bind/dub/dub.cpp',
        'src/bind/osc_core.cpp',
        'src/osc.cpp',
        'src/vendor/osc/OscOutboundPacketStream.cpp',
        'src/vendor/osc/OscPrintReceivedElements.cpp',
        'src/vendor/osc/OscReceivedElements.cpp',
        'src/vendor/osc/OscTypes.cpp',
      },
      incdirs   = {'include', 'src/bind', 'src/vendor'},
    },
  },
}

