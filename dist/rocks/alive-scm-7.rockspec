package = "alive"
version = "scm-7"

source = {
  url = "git://github.com/s-ol/alive.git",
}

description = {
  summary = "Experimental livecoding environment with persistent expressions",
  detailed = [[
This is an experimental livecoding language and environment, in which
expressions persist and update until they are removed from the source code, and
the interpreter keeps no state that you cannot manipulate directly in the
source. This yields a direct-manipulation like experience with a purely
text-based language and works without special editor support.]],
  homepage = "https://alv.s-ol.nu",
  license = "GPL-3",
}

dependencies = {
  "lua",
  "moonscript >= 0.5.0",
  "lpeg",
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
      ["alv.base.pureop"] = "alv/base/pureop.moon",
      ["alv.builtins"] = "alv/builtins.moon",
      ["alv.cell"] = "alv/cell.moon",
      ["alv.copilot.base"] = "alv/copilot/base.moon",
      ["alv.copilot.cli"] = "alv/copilot/cli.moon",
      ["alv.copilot.fltk"] = "alv/copilot/fltk.moon",
      ["alv.copilot.udp"] = "alv/copilot/udp.moon",
      ["alv.copilot.wx"] = "alv/copilot/wx.moon",
      ["alv.cycle"] = "alv/cycle.moon",
      ["alv.error"] = "alv/error.moon",
      ["alv.init"] = "alv/init.moon",
      ["alv.invoke"] = "alv/invoke.moon",
      ["alv.logger"] = "alv/logger.moon",
      ["alv.module"] = "alv/module.moon",
      ["alv.parsing"] = "alv/parsing.moon",
      ["alv.registry"] = "alv/registry.moon",
      ["alv.result.base"] = "alv/result/base.moon",
      ["alv.result.const"] = "alv/result/const.moon",
      ["alv.result.evt"] = "alv/result/evt.moon",
      ["alv.result.init"] = "alv/result/init.moon",
      ["alv.result.io"] = "alv/result/io.moon",
      ["alv.result.sig"] = "alv/result/sig.moon",
      ["alv.rtnode"] = "alv/rtnode.moon",
      ["alv.scope"] = "alv/scope.moon",
      ["alv.tag"] = "alv/tag.moon",
      ["alv.type"] = "alv/type.moon",
      ["alv.util"] = "alv/util.moon",
      ["alv.version"] = "alv/version.moon",

      ["alv-lib.array"] = "alv-lib/array.moon",
      ["alv-lib.logic"] = "alv-lib/logic.moon",
      ["alv-lib.math"] = "alv-lib/math.moon",
      ["alv-lib.midi"] = "alv-lib/midi.moon",
      ["alv-lib.midi.core"] = "alv-lib/midi/core.moon",
      ["alv-lib.midi.launchctl"] = "alv-lib/midi/launchctl.moon",
      ["alv-lib.osc"] = "alv-lib/osc.moon",
      ["alv-lib.pilot"] = "alv-lib/pilot.moon",
      ["alv-lib.random"] = "alv-lib/random.moon",
      ["alv-lib.rhythm"] = "alv-lib/rhythm.moon",
      ["alv-lib.sc"] = "alv-lib/sc.moon",
      ["alv-lib.string"] = "alv-lib/string.moon",
      ["alv-lib.struct"] = "alv-lib/struct.moon",
      ["alv-lib.time"] = "alv-lib/time.moon",
      ["alv-lib.util"] = "alv-lib/util.moon",
      ["alv-lib.vis"] = "alv-lib/vis.moon",
    },
    bin = {
      "bin/alv",
      "bin/alv-wx",
      "bin/alv-fltk",
    },
  },
}
