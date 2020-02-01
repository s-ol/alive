# alive-coding

This is an experimental livecoding langauge and environment, in which
expressions persist and update until they are removed from the source code, and
the interpreter keeps no state that you cannot manipulate directly in the
source. All this is enabled with a purely text-based language and works without
special editor support.

## dependencies

- [MoonScript][moonscript]: `luarocks install moonscript`
- [luafilesystem][lfs]:     `luarocks install luafilesystem`
- [LPeg][lpeg]:             `luarocks install lpeg`
- [osc][osc]:               `luarocks install osc`
- [socket][socket]:         `luarocks install luasocket` (not required in love2d)
- [posix][posix]:           `luarocks install luaposix` (not required in love2d)

## running

headless / standalone:

    $ moon init.moon <session.alv>

or in [LÖVE][love2d] (make sure to install the required modules for lua5.1):

    $ love . <session.alv>

running in LÖVE adds the additional `gui` module. See [`lib/gui.moon`](lib/gui).

[moonscript]: https://moonscript.org/
[lfs]:        https://keplerproject.github.io/luafilesystem/
[lpeg]:       http://www.inf.puc-rio.br/~roberto/lpeg/
[osc]:        https://github.com/lubyk/osc
[posix]:      https://github.com/luaposix/luaposix
[socket]:     http://w3.impa.br/~diego/software/luasocket/
[love2d]:     https://love2d.org/
