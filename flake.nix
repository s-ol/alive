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
        mkDeps = { lua, luaPkgs }:
        let
          luarocks-build-cpp = luaPkgs.buildLuarocksPackage rec {
            pname = "luarocks-build-cpp";
            version = "0.2.0-1";

            knownRockspec = (pkgs.fetchurl {
              url = "mirror://luarocks/${pname}-${version}.rockspec";
              hash = "sha256-AzDZV9u6V71YNJFBfj3cR1COjFFWhGmsJkGsUMErSZs=";
            }).outPath;

            src = pkgs.fetchFromGitHub {
              owner = "osch";
              repo = pname;
              rev = "v0.2.0";
              hash = "sha256-PamppWdV3cQMDK+t2V09/cNRskGuRNeuyvUODmopLaQ=";
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
              url = "mirror://luarocks/${pname}-${version}.src.rock";
              hash = "sha256-Dp3bKIG4swrD4+1NNtRTgyj68Di2cSUlh1r7Z2Rkzn0=";
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
              url = "mirror://luarocks/${pname}-${version}.src.rock";
              hash = "sha256-fD31FruqVriMecFcvSV4W7JRia38+bg7j3T5k5pFZec=";
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
              url = "mirror://luarocks/${pname}-${version}.src.rock";
              hash = "sha256-MArhj51V1awF5k2zToFYEXpS2c6o8bnNDn4wLhooHos=";
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
              url = mirror://luarocks/discount-0.4-1.rockspec;
              hash = "sha256-7bIW6KKFNPGNiVB3m1DasIPI8znq7ZC2iBS5fCevglU=";
            }).outPath;

            src = pkgs.fetchurl {
              url = https://craigbarnes.gitlab.io/dist/lua-discount/lua-discount-0.4.tar.gz;
              hash = "sha256-NTHu3d5KidW3pKubNZp/AaiKyF3U+sYVVOsZkWXP3q0=";
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
              url = "mirror://luarocks/${pname}-${version}.rockspec";
              hash = "sha256-PHQhpQPfmlPhwIXoce5WZ+eoARmSecy1ac7Bfu4zg38=";
            }).outPath;

            src = pkgs.fetchFromGitHub {
              owner = "s-ol";
              repo = "LDoc";
              rev = "moonscript";
              hash = "sha256-3jieGp9++cWtLMKccP+xqrtdCiNG/9BYZlHmH1l8XV8=";
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
            version = "1.0.0-1";

            # src = pkgs.fetchurl {
            #   url = "mirror://luarocks/${pname}-${version}.src.rock";
            #   hash = "sha256-DmSfrQRX8oziH+vvwq3KIdvjTX7P4zeKc6NeTygoU3A=";
            # };
            src = pkgs.fetchFromGitHub {
              owner = "s-ol";
              repo = "lua-rtmidi";
              rev = "v1.0.0";
              hash = "sha256-DmSfrQRX8oziH+vvwq3KIdvjTX7P4zeKc6NeTygoU3A=";
            };

            buildInputs = with pkgs; [ stdenv.cc.cc.lib ];
            propagatedBuildInputs = with pkgs; [ lua alsa-lib libjack2 ];

            meta = {
              homepage = "https://github.com/s-ol/lua-rtmidi";
              description = "Lua bindings for RtMidi";
              license = lib.licenses.bsd2;
            };
          };
        in
          with luaPkgs; [
            moonscript lpeg
            luafilesystem luasocket luasystem fltk4lua losc bit32
            ldoc busted discount
            lua-rtmidi
          ];
      in rec {
        packages.alive = lua53Packages.buildLuarocksPackage rec {
          pname = "alive";
          version = "scm-10";

          src = ./.;
          knownRockspec = ./dist/rocks/${pname}-${version}.rockspec;

          propagatedBuildInputs = with pkgs; [ lua5_3 ]
            ++ (mkDeps { lua = lua5_3; luaPkgs = lua53Packages; });

          meta = {
            homepage = "https://github.com/s-ol/lua-rtmidi";
            description = "Lua bindings for RtMidi";
            license = lib.licenses.bsd2;
          };
        };
        defaultPackage = packages.alive;
        defaultApp = { type = "app"; program = "${defaultPackage}/bin/alv-fltk"; };

        devShells.lua53 =
          let
            lua = pkgs.lua5_3;
            deps = (mkDeps { lua = lua; luaPkgs = pkgs.lua53Packages; });
          in stdenv.mkDerivation {
            name = "alive-env-lua53";
            src = self;

            propagatedBuildInputs = [ (lua.withPackages (o: deps)) ] ++ deps;

            shellHook = ''
              export LUA_PATH="?.lua;?/init.lua"
            '';
          };

        devShells.luajit =
          let
            lua = pkgs.lua5_3;
            deps = (mkDeps { lua = lua; luaPkgs = pkgs.lua53Packages; });
          in stdenv.mkDerivation {
            name = "alive-env-luajit";
            src = self;

            propagatedBuildInputs = [ (lua.withPackages (o: deps)) love_11 ] ++ deps;

            shellHook = ''
              source <(
                LUA_PATH="?.lua;?/init.lua" luajit -e \
                "print(string.format('export LUA_PATH=%q; export LUA_CPATH=%q', package.path, package.cpath))"
              )
            '';
          };
        devShell = devShells.lua53;
      }
    );
}
