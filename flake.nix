{
  description = "A flake for building Minetest Game Engine version 5.5";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Or a specific release like nixos-23.11
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        irrlichtmt-src = pkgs.fetchFromGitHub {
          owner = "minetest";
          repo = "irrlicht";
          rev = "53db262bd224516547fe7e0e05698d9624cf3d61";
          hash = "sha256-YlXn9LrfGkjdb8+zQGDgrInolUYj9nVSF2AXWFpEEkw=";
        };

        minetest-5_5 = (pkgs.overrideCC pkgs.stdenv pkgs.gcc14).mkDerivation rec {
          pname = "minetest";
          version = "44c2e33c78b54835c153d100487600348bd6dee7";

          src = pkgs.fetchFromGitHub {
            owner = "luanti-org";
            repo = "luanti";
            rev = version;
            hash = "sha256-ssaDy6tYxhXGZ1+05J5DwoKYnfhKIKtZj66DOV84WxA=";
          };

          buildInputs = [
            pkgs.libpng
            pkgs.libjpeg
            pkgs.xorg.libXxf86vm
            pkgs.xorg.libXi
            pkgs.libGL
            pkgs.SDL2
            pkgs.xorg.libX11
            pkgs.xorg.libXext
            pkgs.xorg.libXfixes
            pkgs.mesa
            pkgs.sqlite
            pkgs.libogg
            pkgs.libvorbis
            pkgs.openalSoft
            pkgs.curl
            pkgs.freetype
            pkgs.zlib
            pkgs.gmp
            pkgs.jsoncpp
            pkgs.zstd
            pkgs.luajit
            pkgs.doxygen
          ];

          nativeBuildInputs = [
            pkgs.cmake
            pkgs.pkg-config
            pkgs.gcc14
            pkgs.gnumake
            pkgs.ninja
          ];

          cmakeFlags = [
            "-G Ninja"
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
            "-DCMAKE_CXX_STANDARD=17"
            "-DENABLE_GETTEXT=ON" # Usually good to enable for translations
            "-DENABLE_FREETYPE=ON"
            "-DENABLE_LEVELDB=OFF" # Set to ON and add pkgs.leveldb to buildInputs if needed
            "-DIRRLICHT_SOURCE_DIR=$(pwd)/lib/irrlichtmt"
            "-DBUILD_SERVER=ON" # Build minetestserver too (optional)
            "-DBUILD_CLIENT=ON"
            "-DENABLE_SPATIAL=1"
            "-DENABLE_SYSTEM_JSONCPP=1"

            "-DCMAKE_INSTALL_BINDIR=bin"
            "-DCMAKE_INSTALL_DATADIR=share"
            "-DCMAKE_INSTALL_DOCDIR=share/doc"
            "-DCMAKE_INSTALL_DOCDIR=share/doc"
            "-DCMAKE_INSTALL_MANDIR=share/man"
            "-DCMAKE_INSTALL_LOCALEDIR=share/locale"
            "-DOpenGL_GL_PREFERENCE=GLVND"
            "-DENABLE_PROMETHEUS=1"
          ];
          NIX_CFLAGS_COMPILE = "-DluaL_reg=luaL_Reg";

      
          postPatch = ''
            echo "Creating lib/irrlichtmt symlink..."
            ln -s ${irrlichtmt-src} lib/irrlichtmt

            find . -name CMakeLists.txt -print0 | xargs -0 --no-run-if-empty sed -i \
              -e 's/set(CMAKE_CXX_STANDARD 11)//g'
            echo "CMakeLists.txt patching finished."
          '';

          meta = with pkgs.lib; {
            description = "An open source voxel game engine. Play one of our many games, mod a game to your liking, make your own game, or play on a multiplayer server.";
            homepage = "https://www.luanti.org";
            platforms = platforms.linux;
            license = licenses.lgpl21Plus;
          };
        };
      in
      {
        packages = {
          minetest = minetest-5_5;
          default = self.packages.${system}.minetest;
        };

      });
}
