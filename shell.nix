{ pkgs ? import <nixpkgs> {}
}:

let

  luarocks-build-cpp = pkgs.lua53Packages.buildLuarocksPackage rec {
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
    propagatedBuildInputs = [ pkgs.lua5_3 ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };

  luarocks-fetch-gitrec = pkgs.lua53Packages.buildLuarocksPackage rec {
    pname = "luarocks-fetch-gitrec";
    version = "0.2-2";

    src = pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.src.rock";
      sha256 = "Dp3bKIG4swrD4+1NNtRTgyj68Di2cSUlh1r7Z2Rkzn0=";
    };
    propagatedBuildInputs = [ pkgs.lua5_3 pkgs.git ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };

  fltk4lua = pkgs.lua53Packages.buildLuarocksPackage rec {
    pname = "fltk4lua";
    version = "0.2-1";

    src = pkgs.fetchurl {
      url    = "mirror://luarocks//${pname}-${version}.src.rock";
      sha256 = "fD31FruqVriMecFcvSV4W7JRia38+bg7j3T5k5pFZec=";
    };
    buildInputs = with pkgs; [ pkgs.fltk libjpeg ];
    propagatedBuildInputs = [ pkgs.lua5_3 luarocks-build-cpp luarocks-fetch-gitrec ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/siffiejoe/lua-fltk4lua/";
      description = "Lua binding to FLTK, the Fast Light ToolKit";
      license.fullName = "MIT";
    };
  };

  discount = pkgs.lua53Packages.buildLuarocksPackage {
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
    propagatedBuildInputs = [ pkgs.lua5_3 ];

    meta = with pkgs.stdenv.lib; {
      homepage = "https://github.com/craigbarnes/lua-discount";
      description = "Lua bindings for the Discount Markdown library";
      license.fullName = "ISC";
    };
  };

  ldoc = pkgs.lua53Packages.buildLuarocksPackage rec {
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
    propagatedBuildInputs = with pkgs.lua53Packages; [
      pkgs.lua5_3 penlight markdown
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
    (lua5_3.withPackages (p: with p; [
      moonscript lpeg
      luafilesystem luasocket luasystem fltk4lua bit32
      ldoc busted discount
    ]))
  ];
  LUA_PATH = "?.lua;?/init.lua";
}
