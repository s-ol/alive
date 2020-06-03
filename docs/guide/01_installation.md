`alv` is written in the Lua programming language, and is compatible with both
Lua 5.3 and luajit.

## unix/linux and mac os
Your distribution should provide you with packages for Lua and Luarocks. On Mac
OS X, both are provided through [homebrew][homebrew]. After installing both of
these, you should be able to start the Lua interpreter from the shell:

    $ lua
    Lua 5.3.5  Copyright (C) 1994-2018 Lua.org, PUC-Rio
    > 

You can exit using `CTRL+C`. If the version you see is not 5.3, double check
your distribution packages or see if it was installed as `lua5.3` or `lua53`.
Similarily, you should be able to run `luarocks`, `luarocks53` or `luarocks5.3`:

    $ luarocks list
    
    Rocks installed for Lua 5.3
    ---------------------------

Again, double check your installation or try adding `--lua-version 5.3` if the
displayed version is not 5.3.

With everything ready to go, you can now install `alv`:

    $ luarocks install alive

To use the copilot GUI, you will also need the `fltk4lua` package, which requires
installing or building FLTK (also available through homebrew).

    $ luarocks install fltk4lua

With the `alive` package, two binaries should have been installed on your system:
`alv` and `alv-fltk`. If you do not find these in your `$PATH`, you may need to
apply the exports from `luarocks path` upon login, e.g. in your `.bashrc`.

## windows
For Windows, a binary package is available from the latest
[github release][:*release*:]. It includes not only the `alv` source code, but
also a compiled version of Lua 5.3 as well as Luarocks and all of `alv`'s
dependencies.

To use the binary package, simply extract the archive and move the folder
wherever you want. You can now start the `hello.alv` example script by dragging
it onto the `alv.bat` or `alv-fltk.bat` file in the folder.

If you are going to use the command-line `alv.bat`, it is recommended to add
the directory containing it to `%PATH%`, so that you can use the `alv` command
anywhere on your system.

[homebrew]: https://brew.sh
[luarocks]: https://github.com/luarocks/luarocks/#installing
