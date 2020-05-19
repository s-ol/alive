#!/bin/bash
cat <<EOF >"dist/$1/README.txt"
alive $2
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
