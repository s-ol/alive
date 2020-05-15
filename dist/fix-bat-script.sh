#!/bin/bash
IN=$1
MODE=$2

head -n 2 $IN

cat <<EOF
set PR=%~dp0..\\
set PP=%PR:\\=/%
EOF

PP="D:/alive_pkg/lua/"
PR=${PP//\//\\\\}\\\\?

if [ "$MODE" = wlua ]; then
  tail -n 2 $IN | \
  sed -r "s|${PR}|%PR%|g" | \
  sed "s|${PP}|%PP%|g" | \
  sed 's|"%PR%bin\\lua5.3.exe"|start "Lua" "%PR%bin\\wlua5.3.exe"|'
else
  tail -n 2 $IN | \
  sed -r "s|${PR}|%PR%|g" | \
  sed "s|${PP}|%PP%|g"
fi
