@ECHO OFF
SETLOCAL
SET PR=%~dp0
SET LUAROCKS_CONFIG=%PR%luarocks.config.lua
%PR%bin\luarocks --lua-dir %PR% --tree %PR% LUA_INCDIR=%PR%include LUA_LIBDIR=%PR%bin %*
