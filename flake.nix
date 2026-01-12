{
  description = "Shoopdaloop Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    src = {
      url = "path:/home/sander/dev/shoopdaloop";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, src }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      packages.${system}.default = pkgs.callPackage ./default.nix { src = src; };

      devShells.${system}.default = pkgs.mkShell {
        inputsFrom = [ self.packages.${system}.default ];
        
        packages = with pkgs; [
          # Additional dev tools
          rust-analyzer
          clippy
          rustfmt
          gdb
        ];

        # Set environment variables for dev shell
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      };
    };
}
