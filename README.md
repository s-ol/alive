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
- [socket][socket]:         `luarocks install luasocket`
- [system][system]:         `luarocks install luasystem`

## running

    $ moon init.moon <session.alv>

[moonscript]: https://moonscript.org/
[lfs]:        https://keplerproject.github.io/luafilesystem/
[lpeg]:       http://www.inf.puc-rio.br/~roberto/lpeg/
[osc]:        https://github.com/lubyk/osc
[system]:     https://github.com/o-lim/luasystem
[socket]:     http://w3.impa.br/~diego/software/luasocket/
