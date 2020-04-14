#!/bin/sh
VERSION="$1"
REVISION="${2:-1}"

if [ "$VERSION" = scm ]; then
  WHERE=
else
  WHERE="
  tag = \"$VERSION\","
  VERSION="${VERSION#v}"
  VERSION=$(echo "$VERSION" | tr -d -)
fi

list_modules() {
  find "$1" -type f -name '*.moon' -exec sh -c '
      MODULE=$(echo "$1" | sed -e "s/\.moon$//" -e "s/\//./g")
      echo "      [\"$MODULE\"] = \"$1\","
    ' sh {} \;
}

cat <<STOP > "rockspecs/alive-$VERSION-$REVISION.rockspec"
package = "alive"
version = "$VERSION-$REVISION"

source = {
  url = "git://github.com/s-ol/alivecoding.git",$WHERE
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
  "lua >= 5.3",
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
$(list_modules alv)

$(list_modules alv-lib)
    },
    bin = {
      "bin/alv",
      "bin/alv-copilot"
    },
  },

  platforms = {
    win32 = {
      install = {
        bin = {
          "bin/alv",
          "bin/alv-copilot.bat",
        },
      },
    },
  },
}
STOP
