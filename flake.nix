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

      zstd-src = pkgs.fetchFromGitHub {
        owner = "facebook";
        repo = "zstd";
        rev = "v1.5.7";
        hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
      };

      imgui-src = pkgs.fetchFromGitHub {
        owner = "ocornut";
        repo = "imgui";
        rev = "v1.91.9b-docking";
        hash = "sha256-mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
      };

      nfd-src = pkgs.fetchFromGitHub {
        owner = "btzy";
        repo = "nativefiledialog-extended";
        rev = "v1.2.1";
        hash = "sha256-GwT42lMZAAKSJpUJE6MYOpSLKUD5o9nSe9lcsoeXgJY=";
      };

      ppqsort-src = pkgs.fetchFromGitHub {
        owner = "GabTux";
        repo = "PPQSort";
        rev = "v1.0.5";
        hash = "sha256-EMZVI/uyzwX5637/rdZuMZoql5FTrsx0ESJMdLVDmfk=";
      };

      packageproject-src = pkgs.fetchFromGitHub {
        owner = "TheLartians";
        repo = "PackageProject.cmake";
        rev = "v1.13.0";
        hash = "sha256-EMZVI/uyzwX5637/rdZuMZoql5FTrsx0ESJMdLVDmfk=";
      };

      tracy = pkgs.tracy.overrideAttrs (oldAttrs: {
        version = "0.12.2";

        src = pkgs.fetchFromGitHub {
          owner = "wolfpld";
          repo = "tracy";
          rev = "v0.12.2";
          hash = "sha256-voHql8ETnrUMef14LYduKI+0LpdnCFsvpt8B6M/ZNmc=";
        };

        preConfigure = ''
          mkdir /tmp/imgui
          cp -ar ${imgui-src}/* /tmp/imgui
          chmod -R 777 /tmp/imgui

          mkdir /tmp/ppqsort
          cp -ar ${ppqsort-src}/* /tmp/ppqsort
          chmod -R 777 /tmp/ppqsort

          mkdir /tmp/packageproject
          cp -ar ${packageproject-src}/* /tmp/packageproject
          chmod -R 777 /tmp/packageproject
        '';

        cmakeFlags = oldAttrs.cmakeFlags ++ [
          (nixpkgs.lib.cmakeFeature "CPM_zstd_SOURCE" "${zstd-src}")
          (nixpkgs.lib.cmakeFeature "CPM_ImGui_SOURCE" "/tmp/imgui")
          (nixpkgs.lib.cmakeFeature "CPM_nfd_SOURCE" "${nfd-src}")
          (nixpkgs.lib.cmakeFeature "CPM_PPQSort_SOURCE" "/tmp/ppqsort")
          (nixpkgs.lib.cmakeFeature "CPM_PackageProject.cmake_SOURCE" "/tmp/packageproject")
        ];
      });
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
          tracy
        ];

        # Set environment variables for dev shell
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      };
    };
}
