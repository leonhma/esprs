{
  inputs = {
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    fenix.url = "github:nix-community/fenix";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, fenix, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  packages = with pkgs; [
                    openssl
                    # libllvm
                    # clang  # needed for idf_tools.py
                    # llvmPackages.bintools  # used for lld (not ld)
                    # glibc.static
                    ldproxy  # used by cargo / esp-ídf
                    # pkg-config  # apparently used to find libs
                    # ninja    # needed for idf_tools.py
                    # ldproxy
                    # glibc.static
                  ];

                  languages.python = {
                    enable = true;
                    # venv.enable = true;
                  };

                  languages.rust = {
                    enable = true;
                    channel = "nightly";
                    # targets = ["riscv32imac-esp-espidf"];
                    components = [ "rustc" "rust-src" "cargo" "clippy" "rustfmt" "rust-analyzer" ];
                  };

                  env = rec {
                    # LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
                    # COMPILER_PATH = "${pkgs.lld}/bin";
                    # requires nix-ld to be enabled system-wide
                    NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
                    NIX_LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [
                      # libllvm
                      # libclang
                      # llvmPackages.libcxxClang
                      # gcc
                      # stdenv.cc
                      # stdenv.cc.cc those are apparently not needed
                      # llvmPackages.bintools same --^
                      # zlib
                      # libxml2
                      systemd  # required for openocd-esp32 (libudev)
                      libusb1  # required for openocd-esp32
                      # glibc.static
                    ])}";
                    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (with pkgs; [
                      stdenv.cc.cc  # libclang depends on it
                      zlib  # needed by libclang
                      libxml2  # needed by libclang
                    ])}";
                  };

                  # enterShell = ''
                  #   cargo install ldproxy
                  # '';

                  # currently broken
                  # pre-commit.hooks = {
                  #   rustfmt.enable = true;
                  #   clippy.enable = true;
                  # };
                }
              ];
            };
          });
    };
}
