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
                    ldproxy  # used by cargo / esp-ídf
                  ];

                  languages.python = {
                    enable = true;
                  };

                  languages.rust = {
                    enable = true;
                    channel = "nightly";
                    components = [ "rustc" "rust-src" "cargo" "clippy" "rustfmt" "rust-analyzer" ];
                    mold.enable = false;
                  };

                  env = {
                    NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
                    NIX_LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [
                      stdenv.cc.cc # provided by system but here again for clarity
                      systemd  # required for openocd-esp32 (libudev)
                      libusb1  # required for openocd-esp32
                    ])}";
                    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath (with pkgs; [
                      stdenv.cc.cc  # libclang depends on it
                      zlib  # needed by libclang
                      libxml2  # needed by libclang
                    ])}";
                  };

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
