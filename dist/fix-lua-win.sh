#!/bin/sh
IN=$1

head -n 2 $IN

cat <<EOF
set PR=%~dp0..\\..\\
set PP=%PR:\\=/%
EOF

PP="D:/alive_pkg/lua/"
PR=${PP//\//\\\\}\\\\?

tail -n 2 $IN | \
sed -r "s|${PR}|%PR%|g" | \
sed "s|${PP}|%PP%|g"
