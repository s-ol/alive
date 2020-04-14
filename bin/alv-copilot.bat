@echo off
setlocal
set PATH=%PATH%;%~dp0\lua\lua\bin
set LUA_PATH=%LUA_PATH%;%~dp0\?.lua;%~dp0\alive\?\init.lua
moon %~dp0\init.moon %*
exit /b %ERRORLEVEL%
