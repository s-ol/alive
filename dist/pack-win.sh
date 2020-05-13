#!/bin/sh

TAG="$1"
ROCKVER="$2"

BUNDLE="alive-$TAG-win"
ROCK="alive-$ROCKVER.all.rock"

set -e

if [ -e "dist/$BUNDLE.zip" ]; then
  echo "dist/$BUNDLE.zip already exists!"
  exit 2
fi

if [ -e "dist/$BUNDLE" ]; then
  echo "dist/$BUNDLE already exists!"
  exit 2
fi

mkdir -p "dist/$BUNDLE"

cp -r docs hello.alv LICENSE "dist/$BUNDLE/"
rm -rf "dist/$BUNDLE/docs/"*.md "dist/$BUNDLE/docs/"*.ltp "dist/$BUNDLE/docs/gen"
unzip dist/lua-win.zip -d "dist/$BUNDLE/"
luarocks --tree "dist/$BUNDLE/lua/lua" install --deps-mode none "dist/rocks/$ROCK"

cat <<EOF >"dist/$BUNDLE/copilot.bat"
@echo off
setlocal
set PATH=%PATH%;%~dp0\\lua\\lua\\bin
set LUA_PATH=%LUA_PATH%;%~dp0\?.lua;%~dp0\?\init.lua
moon "%~dp0\\lua\\lua\\lib\\luarocks\\rocks-5.3\\alive\\$ROCKVER\\bin\\alv" %*
exit /b %ERRORLEVEL%
EOF

mkdir "dist/$BUNDLE/alv-lib"
cat <<EOF >"dist/$BUNDLE/alv-lib/README.txt"
You can use this directory to add extensions to alv.
See the extension documentation here for more information:

https://alv.s-ol.nu/stable/internals/topics/extensions.md.html
EOF

cat <<EOF >"dist/$BUNDLE/README.md"
alive $TAG
==========

https://alv.s-ol.nu
https://github.com/s-ol/alive

License
-------
alive is licensed under the GPLv3 free and open-source license, a copy of which
you can find in the file \`LICENSE\`.

This binary distribution of alive contains the Lua interpreter, LuaRocks package
manager, and a number of Lua modules licensed under various terms. Lua and
LuaRocks are both licensed under the MIT license. The packages can be found
within the \`lua/lua\` directory while their individual licensing information
may be viewed using \`luarocks.bat\`:

    cmd.exe> luarocks.bat list
    cmd.exe> luarocks.bat show moonscript
    cmd.exe> luarocks.bat show ...
EOF

(
  cd dist/
  zip -rm "$BUNDLE.zip" "$BUNDLE"
)
