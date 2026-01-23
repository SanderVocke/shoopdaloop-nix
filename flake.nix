{
  description = "Shoopdaloop Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    src = {
      url = "path:/home/sander/dev/shoopdaloop";
      flake = false;
    };
    tracy-nix.url = "github:SanderVocke/tracy-nix";
  };

  outputs = { self, nixpkgs, src, tracy-nix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      packages.${system}.default = pkgs.callPackage ./default.nix { src = src; };

      devShells.${system}.default = pkgs.mkShell {
        # For some reason, the qt6.wrapQtAppsHook is not picked up by the dev shell,
        # so just don't use the hooks at all if used as such
        inputsFrom = [
          (self.packages.${system}.default.overrideAttrs (old: {
            nativeBuildInputs = pkgs.lib.filter (p: p != pkgs.qt6.wrapQtAppsHook) (old.nativeBuildInputs or [ ]);
          }))
        ];
        
        packages = with pkgs; [
          # Additional dev tools
          rust-analyzer
          clippy
          rustfmt
          gdb
          tracy-nix.packages.${system}.default
        ];

        # Set environment variables for dev shell
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

        # Disable hardening (doesn't work for full debug builds)
        hardeningDisable = [ "all" ];
      };
    };
}
