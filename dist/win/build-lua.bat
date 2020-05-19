cd %~dp0deps

cd lua-5.3.5
del /F /Q bin include
mkdir bin
mkdir include
copy /Y ..\wlua.c src
copy /Y src\lua*.h include
copy /Y src\lua.hpp include
copy /Y src\lauxlib.h include

cd src
del *.obj *.o *.lib
cl /MD /O2 /c /DLUA_BUILD_AS_DLL *.c
ren lua.obj lua.o
ren luac.obj luac.o
ren wlua.obj wlua.o
link /DLL /IMPLIB:lua5.3.5.lib /OUT:../bin/lua5.3.dll *.obj
copy lua5.3.5.lib ..\bin\lua5.3.lib
link /OUT:../bin/lua5.3.exe /SUBSYSTEM:CONSOLE lua.o lua5.3.5.lib
link /OUT:../bin/wlua5.3.exe /SUBSYSTEM:WINDOWS wlua.o lua.o lua5.3.5.lib
lib /OUT:lua5.3.5-static.lib *.obj
link /OUT:../bin/luac5.3.exe /SUBSYSTEM:CONSOLE luac.o lua5.3.5-static.lib
cd ../..