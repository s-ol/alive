{ pkgs ? import <nixpkgs> {}
}:

let
  # lua = pkgs.lua5_3;
  # luaPkgs = pkgs.lua53Packages;
  lua = pkgs.luajit;
  luaPkgs = pkgs.luajitPackages;

  luarocks-build-cpp = luaPkgs.buildLuarocksPackage rec {
    pname = "luarocks-build-cpp";
    version = "0.2.0-1";

    knownRockspec = (pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.rockspec";
      sha256 = "AzDZV9u6V71YNJFBfj3cR1COjFFWhGmsJkGsUMErSZs=";
    }).outPath;

    src = pkgs.fetchFromGitHub {
      owner = "osch";
      repo = pname;
      rev = "v0.2.0";
      sha256 = "PamppWdV3cQMDK+t2V09/cNRskGuRNeuyvUODmopLaQ=";
    };
    propagatedBuildInputs = [ lua ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };

  luarocks-fetch-gitrec = luaPkgs.buildLuarocksPackage rec {
    pname = "luarocks-fetch-gitrec";
    version = "0.2-2";

    src = pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.src.rock";
      sha256 = "Dp3bKIG4swrD4+1NNtRTgyj68Di2cSUlh1r7Z2Rkzn0=";
    };
    propagatedBuildInputs = with pkgs; [ lua git ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };

  fltk4lua = luaPkgs.buildLuarocksPackage rec {
    pname = "fltk4lua";
    version = "0.2-1";

    src = pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.src.rock";
      sha256 = "fD31FruqVriMecFcvSV4W7JRia38+bg7j3T5k5pFZec=";
    };
    buildInputs = with pkgs; [ fltk libjpeg ];
    propagatedBuildInputs = [ lua luarocks-build-cpp luarocks-fetch-gitrec ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };

  losc = luaPkgs.buildLuarocksPackage rec {
    pname = "losc";
    version = "1.0.0-1";

    src = pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.src.rock";
      sha256 = "MArhj51V1awF5k2zToFYEXpS2c6o8bnNDn4wLhooHos=";
    };
    buildInputs = with pkgs; [ stdenv.cc.cc.lib ];
    propagatedBuildInputs = [ lua ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/davidgranstrom/losc";
      description = "Open Sound Control (OSC) for lua/luajit with no external dependencies.";
      license.fullName = "MIT";
    };
  };

  discount = luaPkgs.buildLuarocksPackage {
    pname = "discount";
    version = "0.4-1";

    knownRockspec = (pkgs.fetchurl {
      url    = https://luarocks.org/discount-0.4-1.rockspec;
      sha256 = "0mc2mwkprf8li2v91vga77rwi0xhv989nxshi66z2d45lbl1dcpd";
    }).outPath;

    src = pkgs.fetchurl {
      url    = https://craigbarnes.gitlab.io/dist/lua-discount/lua-discount-0.4.tar.gz;
      sha256 = "1bfyrxjr26gbahawdynlbp48ma01gyd3b6xbljvxb2aavvfywc9m";
    };

    buildInputs = [ pkgs.discount ];
    propagatedBuildInputs = [ lua ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/craigbarnes/lua-discount";
      description = "Lua bindings for the Discount Markdown library";
      license.fullName = "ISC";
    };
  };

  ldoc = luaPkgs.buildLuarocksPackage rec {
    pname = "ldoc";
    version = "scm-2";

    knownRockspec = (pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.rockspec";
      sha256 = "PHQhpQPfmlPhwIXoce5WZ+eoARmSecy1ac7Bfu4zg38=";
    }).outPath;

    src = pkgs.fetchFromGitHub {
      owner = "s-ol";
      repo = "LDoc";
      rev = "moonscript";
      sha256 = "3jieGp9++cWtLMKccP+xqrtdCiNG/9BYZlHmH1l8XV8=";
    };
    propagatedBuildInputs = with luaPkgs; [
      lua penlight markdown
    ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };
  
in pkgs.mkShell {
  name = "alv-env";
  buildInputs = with pkgs; [
    (lua.withPackages (p: with p; [
      moonscript lpeg
      luafilesystem luasocket luasystem fltk4lua losc bit32
      ldoc busted discount
    ]))
    love_11
  ];
  shellHook = ''
    echo 'setting paths'
    source <(
      LUA_PATH="?.lua;?/init.lua" luajit -e \
      "print(string.format('export LUA_PATH=%q; export LUA_CPATH=%q', package.path, package.cpath))"
    )
  '';
}
