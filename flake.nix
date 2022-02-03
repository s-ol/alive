{
  description = "alive";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      with import nixpkgs { inherit system; };
      let
        mkLua = { lua, luaPkgs }:
        let
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

            meta = {
              homepage = "https://github.com/osch/luarocks-build-cpp";
              description = "A fork of built-in build system for C++ rocks";
              license = lib.licenses.mit;
            };
          };

          luarocks-fetch-gitrec = luaPkgs.buildLuarocksPackage rec {
            pname = "luarocks-fetch-gitrec";
            version = "0.2-2";

            src = pkgs.fetchurl {
              url    = "mirror://luarocks//${pname}-${version}.src.rock";
              sha256 = "Dp3bKIG4swrD4+1NNtRTgyj68Di2cSUlh1r7Z2Rkzn0=";
            };
            postUnpack = "sourceRoot=$sourceRoot/luarocks-fetch-gitrec-0.2";

            propagatedBuildInputs = with pkgs; [ lua git ];

            meta = {
              homepage = "https://github.com/siffiejoe/luarocks-fetch-gitrec";
              description = "Lua binding to FLTK, the Fast Light ToolKit";
              license = lib.licenses.mit;
            };
          };

          fltk4lua = luaPkgs.buildLuarocksPackage rec {
            pname = "fltk4lua";
            version = "0.2-1";

            src = pkgs.fetchurl {
              url    = "mirror://luarocks//${pname}-${version}.src.rock";
              sha256 = "fD31FruqVriMecFcvSV4W7JRia38+bg7j3T5k5pFZec=";
            };
            postUnpack = "sourceRoot=$sourceRoot/lua-fltk4lua";
            buildInputs = with pkgs; [ fltk libjpeg ];
            propagatedBuildInputs = [ lua luarocks-build-cpp luarocks-fetch-gitrec ];

            meta = {
              homepage = "https://github.com/siffiejoe/lua-fltk4lua";
              description = "Lua binding to FLTK, the Fast Light ToolKit";
              license = lib.licenses.mit;
            };
          };

          losc = luaPkgs.buildLuarocksPackage rec {
            pname = "losc";
            version = "1.0.0-1";

            src = pkgs.fetchurl {
              url    = "mirror://luarocks//${pname}-${version}.src.rock";
              sha256 = "MArhj51V1awF5k2zToFYEXpS2c6o8bnNDn4wLhooHos=";
            };
            postUnpack = "sourceRoot=$sourceRoot/losc";

            buildInputs = with pkgs; [ stdenv.cc.cc.lib ];
            propagatedBuildInputs = [ lua ];

            meta = {
              homepage = "https://github.com/davidgranstrom/losc";
              description = "Open Sound Control (OSC) for lua/luajit with no external dependencies.";
              license = lib.licenses.mit;
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

            meta = {
              homepage = "https://github.com/craigbarnes/lua-discount";
              description = "Lua bindings for the Discount Markdown library";
              license = lib.licenses.isc;
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

            meta = {
              homepage = "https://github.com/s-ol/LDoc";
              description = "A Lua Documentation Tool";
              license = lib.licenses.mit;
            };
          };

          lua-rtmidi = luaPkgs.buildLuarocksPackage rec {
            pname = "lua-rtmidi";
            version = "dev-1";

            src = pkgs.fetchFromGitHub {
              owner = "s-ol";
              repo = "lua-rtmidi";
              rev = "master";
              sha256 = "iXckraQZf6smWlxD27ktBEFKNXLzzsZFpzx2MLRQJVM=";
            };
            buildInputs = with pkgs; [ stdenv.cc.cc.lib ];
            propagatedBuildInputs = with pkgs; [ lua alsa-lib pipewire.jack ];

            meta = {
              homepage = "https://github.com/s-ol/lua-rtmidi";
              description = "Lua bindings for RtMidi";
              license = lib.licenses.bsd2;
            };
          };
        in
          (lua.withPackages (p: with p; [
            moonscript lpeg
            luafilesystem luasocket luasystem fltk4lua losc bit32
            ldoc busted discount
            lua-rtmidi
          ]));
      in rec {
        packages.alive-env-lua53 = stdenv.mkDerivation {
          name = "alive-env-lua53";
          src = self;

          nativeBuildInputs = with pkgs; [ (mkLua { lua = lua5_3; luaPkgs = lua53Packages; }) ];

          shellHook = ''
            export LUA_PATH="?.lua;?/init.lua"
          '';
        };

        packages.alive-env-luajit = stdenv.mkDerivation {
          name = "alive-env-luajit";
          src = self;

          nativeBuildInputs = with pkgs; [
            (mkLua { lua = luajit; luaPkgs = luajitPackages; })
            love_11
          ];

          shellHook = ''
            source <(
              LUA_PATH="?.lua;?/init.lua" luajit -e \
              "print(string.format('export LUA_PATH=%q; export LUA_CPATH=%q', package.path, package.cpath))"
            )
          '';
        };

        defaultPackage = packages.alive-env-luajit;
      }
    );
}
