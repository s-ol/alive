#!/bin/sh

TAG="$1"
ROCKVER="$2"
LUA_WIN="$3"
if [ -z "$LUA_WIN" ]; then
  LUA_WIN="/mnt/d/alive_pkg/lua"
fi

BUNDLE="alive-$TAG-win"
ROCK="alive-$ROCKVER.all.rock"

set -e

if [ "$TAG" = "test" ]; then
  rm -rf "dist/$BUNDLE" "dist/$BUNDLE.zip"
fi

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
cp -r "$LUA_WIN" "dist/$BUNDLE/"

cat <<EOF >"dist/$BUNDLE/alv.bat"
@echo off
%~dp0lua\bin\alv.bat --nocolor %*
exit /b %ERRORLEVEL%
EOF

cat <<EOF >"dist/$BUNDLE/alv-fltk.bat"
@echo off
%~dp0lua\bin\alv-fltk.bat %*
exit /b %ERRORLEVEL%
EOF

for script in "dist/$BUNDLE/lua/bin/"*.bat; do
  case "$(basename "$script" .bat)" in
    alv-fltk|alv-wx) mode="wlua" ;;
    *) mode= ;;
  esac
  dist/fix-bat-script.sh "$script" $mode > "$script.nu"
  mv "$script.nu" "$script"
done

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
within the \`lua\` directory while their individual licensing information may be
viewed using \`luarocks.bat\`:

    cmd.exe> luarocks.bat list
    cmd.exe> luarocks.bat show moonscript
    cmd.exe> luarocks.bat show ...
EOF

(
  cd dist/
  zip -rm "$BUNDLE.zip" "$BUNDLE"
)
