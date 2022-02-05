# alive-coding

This is an experimental livecoding language and environment, in which
expressions persist and update until they are removed from the source code, and
the interpreter keeps no state that you cannot manipulate directly in the
source. This yields a direct-manipulation like experience with a purely
text-based language and works without special editor support.

This README contains a short overview over installation and development
processes. For more information, visit the full [online documentation][docs].

## dependencies

- [MoonScript][moonscript]: `luarocks install moonscript`
- [luafilesystem][lfs]*:    `luarocks install luafilesystem`
- [LPeg][lpeg]*:            `luarocks install lpeg`
- [socket][socket]:         `luarocks install luasocket`
- [system][system]:         `luarocks install luasystem`
- [losc][losc]:             `luarocks install losc` (optional)
- [lua-rtmidi][rtmidi]:     `luarocks install lua-rtmidi` (optional)
- [busted][busted]:         `luarocks install busted` (optional, for tests)
- [discount][discount]:     `luarocks install discount` (optional, for docs)
- [ldoc][ldoc]:             `luarocks install
  https://raw.githubusercontent.com/s-ol/LDoc/moonscript/ldoc-scm-2.rockspec`
  (optional, for docs)

\* these are also `moonscript` dependencies and do not neet to be installed
manually.

## docs

With `make` the HTML documentation is generated in `docs/`.
The latest documentation is publicly available online at [alv.s-ol.nu][docs].
 
## starting the copilot

    $ bin/alv examples/hello.alv
    
For more information see the [getting started guide][guide].

### LÖVE / visuals

To use the 'love' module for relatime 2d graphics, the copilot needs to be
started using [love2d][love] (0.11+):

    $ bin/alv-love examples/love2d.alv

## running the tests

The tests use the [busted][busted] Lua unit testing framework. To run all
tests, simply start busted in the main directory:

    $ busted

To run individual test files, for example to speed up execution during
development, simply pass the files as arguments:

    $ busted spec/value_spec.moon

[moonscript]: https://moonscript.org/
[lfs]:        https://keplerproject.github.io/luafilesystem/
[lpeg]:       http://www.inf.puc-rio.br/~roberto/lpeg/
[losc]:       https://github.com/davidgranstrom/losc
[system]:     https://github.com/o-lim/luasystem
[socket]:     http://w3.impa.br/~diego/software/luasocket/
[rtmidi]:     https://github.com/s-ol/lua-rtmidi/
[busted]:     https://olivinelabs.com/busted/
[discount]:   https://luarocks.org/modules/craigb/discount
[ldoc]:       https://github.com/s-ol/LDoc
[love]:       https://love2d.org/

[docs]:       https://alv.s-ol.nu
[guide]:      https://alv.s-ol.nu/guide.html
