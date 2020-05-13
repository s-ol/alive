package = "alive"
version = "0.1-1"

source = {
  url = "git://github.com/s-ol/alive.git",
  tag = "v0.1",
}

description = {
  summary = "Experimental livecoding environment with persistent expressions",
  detailed = [[
This is an experimental livecoding language and environment, in which
expressions persist and update until they are removed from the source code, and
the interpreter keeps no state that you cannot manipulate directly in the
source. This yields a direct-manipulation like experience with a purely
text-based language and works without special editor support.]],
  homepage = "https://alive.s-ol.nu",
  license = "GPL-3",
}

dependencies = {
  "lua",
  "moonscript >= 0.5.0",
  "lpeg ~> 0.10",
  "luafilesystem",
  "luasystem",
  "luasocket",
  "osc",
}

build = {
  type = "builtin",
  modules = {},
  copy_directories = { "docs" },
  install = {
    lua = {
      ["alv.ast"] = "alv/ast.moon",
      ["alv.base.builtin"] = "alv/base/builtin.moon",
      ["alv.base.fndef"] = "alv/base/fndef.moon",
      ["alv.base.init"] = "alv/base/init.moon",
      ["alv.base.input"] = "alv/base/input.moon",
      ["alv.base.match"] = "alv/base/match.moon",
      ["alv.base.op"] = "alv/base/op.moon",
      ["alv.builtin"] = "alv/builtin.moon",
      ["alv.cell"] = "alv/cell.moon",
      ["alv.copilot"] = "alv/copilot.moon",
      ["alv.cycle"] = "alv/cycle.moon",
      ["alv.error"] = "alv/error.moon",
      ["alv.init"] = "alv/init.moon",
      ["alv.invoke"] = "alv/invoke.moon",
      ["alv.logger"] = "alv/logger.moon",
      ["alv.module"] = "alv/module.moon",
      ["alv.parsing"] = "alv/parsing.moon",
      ["alv.registry"] = "alv/registry.moon",
      ["alv.result"] = "alv/result.moon",
      ["alv.scope"] = "alv/scope.moon",
      ["alv.stream.base"] = "alv/stream/base.moon",
      ["alv.stream.event"] = "alv/stream/event.moon",
      ["alv.stream.init"] = "alv/stream/init.moon",
      ["alv.stream.io"] = "alv/stream/io.moon",
      ["alv.stream.value"] = "alv/stream/value.moon",
      ["alv.tag"] = "alv/tag.moon",
      ["alv.version"] = "alv/version.moon",

      ["alv-lib.logic"] = "alv-lib/logic.moon",
      ["alv-lib.math"] = "alv-lib/math.moon",
      ["alv-lib.midi"] = "alv-lib/midi.moon",
      ["alv-lib.midi.core"] = "alv-lib/midi/core.moon",
      ["alv-lib.midi.launchctl"] = "alv-lib/midi/launchctl.moon",
      ["alv-lib.osc"] = "alv-lib/osc.moon",
      ["alv-lib.pilot"] = "alv-lib/pilot.moon",
      ["alv-lib.random"] = "alv-lib/random.moon",
      ["alv-lib.sc"] = "alv-lib/sc.moon",
      ["alv-lib.string"] = "alv-lib/string.moon",
      ["alv-lib.time"] = "alv-lib/time.moon",
      ["alv-lib.util"] = "alv-lib/util.moon",
    },
    bin = {
      "bin/alv",
      "bin/alv-wx"
    },
  },
}
