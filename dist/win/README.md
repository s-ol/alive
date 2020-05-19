Building & Packaging on Windows
===============================

1. download and build dependencies
   - Lua:
     - download `lua-5.3.5.tar.gz` and extract in `dist/win/deps`
     - run `dist\\win\\build-lua.bat`
   - luarocks:
     - downlaod `luarocks-3.3.1-windows-64.zip` and extract in `dist/win/deps`
   - FLTK:
     - download `fltk-1.3.5-source.tar.gz` and extract in `dist/win/deps`
     - compile the fltkdll project in `fltk-*/ide/VisualC2010/` in Release mode
2. build or obtain an alive binary rock (`alive-VERSION-REVISION.all.rock`)
3. run `dist\\release.bat VERSION path\to\alive-VERSION-REVISION.all.rock`
4. zip `dist\alive-VERSION-win` and distribute
