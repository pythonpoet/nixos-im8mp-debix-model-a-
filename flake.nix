# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "mesh-communicator - Ghaf based configuration";

  # nixConfig = {
  #   extra-trusted-substituters = [
  #     "https://cache.vedenemo.dev"
  #     "https://cache.ssrcdevops.tii.ae"
  #   ];
  #   extra-trusted-public-keys = [
  #     "cache.vedenemo.dev:8NhplARANhClUSWJyLVk4WMyy1Wb4rhmWW2u8AejH9E="
  #     "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
  #   ];
  # };

  nixConfig = {
    # Configure builders directly in the flake
    builders = [
      "ssh://david@192.168.1.31 x86_64-linux /home/david/.ssh/path/to/ssh/key/id_ed25519.pub - 4 2 kvm"
      "ssh://david@192.168.1.99 x86_64-linux /home/david/.ssh/path/to/ssh/key/id_rsa.pub.pub - 4 2"
      #"ssh://user@arm-builder aarch64-linux /path/to/ssh/key - 4 1" # Native ARM builder
    ];
    
    # Optional: Binary cache settings
    extra-substituters = ["https://cache.nixos.org" "https://your-cache.cachix.org"];
    trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ghaf = {
      url = "github:tiiuae/ghaf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        nixos-hardware.follows = "nixos-hardware";
        flake-parts.follows = "flake-parts";
      };
    };
  };

  outputs = inputs @ {
    flake-parts,
    ghaf,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake
    {
      inherit inputs;
      specialArgs = {
        inherit (ghaf) lib;
      };
    } {
      systems = [
        "x86_64-linux"
      ];

      imports = [
        ./targets
      ];
            # ADD THIS OVERLAY TO FIX WOLFSSL
      perSystem = {config, pkgs, ...}: {
        _module.args.pkgs = import nixpkgs {
          system = config.system;
          overlays = [
            (final: prev: {
              wolfssl = prev.wolfssl.overrideAttrs (old: {
                doCheck = false;
              });
            })
          ];
        };
      };
    };
}

