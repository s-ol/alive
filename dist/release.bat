SETLOCAL
SET TAG=%1
SET ROCK=%2
SET DEPS=%~dp0win\deps
SET BUNDLE=alive-%TAG%-win
rmdir /Q /S dist\%BUNDLE%
mkdir dist\%BUNDLE%

mkdir dist\%BUNDLE%\lua
mkdir dist\%BUNDLE%\lua\bin
mkdir dist\%BUNDLE%\lua\include
copy /Y %DEPS%\lua-5.3.5\bin\* dist\%BUNDLE%\lua\bin\
copy /Y %DEPS%\lua-5.3.5\include\* dist\%BUNDLE%\lua\include\
copy /Y %DEPS%\luarocks-3.3.1-windows-64\luarocks.exe dist\%BUNDLE%\lua\bin\
copy /Y hello.alv dist\%BUNDLE%\
copy /Y LICENSE dist\%BUNDLE%\LICENSE.txt
xcopy /E /I docs dist\%BUNDLE%\docs
xcopy /E /I dist\win\wrappers\* dist\%BUNDLE%\

cd dist\%BUNDLE%\lua
call luarocks install busted
call luarocks install luarocks-fetch-gitrec
call luarocks install luarocks-build-cpp
call luarocks install %DEPS%\fltk4lua-0.1-1.rockspec FLTK_LIBDIR=%DEPS%\fltk-1.3.5\lib FLTK_INCDIR=%DEPS%\fltk-1.3.5
call luarocks --server https://luarocks.org/manifests/s-ol install %ROCK%
cd ..\..\..

set DIST_UNIX=%~dp0%BUNDLE%\lua\
set DIST_UNIX=%DIST_UNIX:\=/%
bash dist/win/fix-paths.sh %DIST_UNIX% %BUNDLE%
sh dist/win/gen-readme.sh %BUNDLE% %TAG%
