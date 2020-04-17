#!/bin/sh

VERSION="$1"
BUNDLE="alive-$VERSION-win"

set -e

if [ -d "dist/$BUNDLE.zip" ]; then
  echo "dist/$BUNDLE.zip already exists!"
  exit 2
fi

git archive "$VERSION:" -o "dist/$BUNDLE.zip" --prefix "$BUNDLE/alive/"

cd dist
unzip "$BUNDLE.zip"
cd "$BUNDLE"

cp -r ../docs .
mv alive/hello.alv .
rm -rf docs/*.md docs/*.ltp docs/gen
rm -rf alive/dist

unzip ../lua-win.zip

cat <<EOF >copilot.bat
@echo off
setlocal
set PATH=%PATH%;%~dp0\lua\lua\bin
set LUA_PATH=%LUA_PATH%;%~dp0\alive\?.lua;%~dp0\alive\?\init.lua
moon %~dp0\alive\init.moon %*
exit /b %ERRORLEVEL%
EOF

cat <<EOF >README.txt
alivecoding $VERSION
====================

https://alive.s-ol.nu
https://github.com/s-ol/alivecoding

License
-------
alive is licensed under the GPLv3 free and open-source license, a copy of which
you can find in the file `alive/LICENSE`.

This binary distribution of alive contains the Lua interpreter, LuaRocks package
manager, and a number of Lua modules licensed under various terms. Lua and
LuaRocks are both licensed under the MIT license, while the packages can be
found within the `lua/lua` directory while their individual licensing
information may be viewed using `luarocks.bat`:

    cmd.exe> luarocks.bat list
    cmd.exe> luarocks.bat show moonscript
    cmd.exe> luarocks.bat show ...
EOF

cd ..
rm "$BUNDLE.zip"
zip -rm "$BUNDLE.zip" "$BUNDLE"
