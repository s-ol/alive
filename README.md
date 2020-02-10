# alive-coding

This is an experimental livecoding language and environment, in which
expressions persist and update until they are removed from the source code, and
the interpreter keeps no state that you cannot manipulate directly in the
source. This yields a direct-manipulation like experience with a purely
text-based language and works without special editor support.

## dependencies

- [MoonScript][moonscript]: `luarocks install moonscript`
- [luafilesystem][lfs]:     `luarocks install luafilesystem`
- [LPeg][lpeg]:             `luarocks install lpeg`
- [osc][osc]:               `luarocks install osc`
- [socket][socket]:         `luarocks install luasocket` (not required in love2d)
- [system][system]:         `luarocks install luasystem` (not required in love2d)

## running

headless / standalone:

    $ moon init.moon <session.alv>

or in [LÖVE][love2d] (make sure to install the required modules for lua5.1):

    $ love . <session.alv>

running in LÖVE adds the additional `gui` module. See [`lib/gui.moon`](lib/gui.moon).

[moonscript]: https://moonscript.org/
[lfs]:        https://keplerproject.github.io/luafilesystem/
[lpeg]:       http://www.inf.puc-rio.br/~roberto/lpeg/
[osc]:        https://github.com/lubyk/osc
[system]:     https://github.com/o-lim/luasystem
[socket]:     http://w3.impa.br/~diego/software/luasocket/
[love2d]:     https://love2d.org/
