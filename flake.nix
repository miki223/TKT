{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  nixConfig = {
    extra-substituters = [
      "https://tkt-cache.cachix.org"
    ];
    extra-trusted-public-keys = [
      "tkt-cache.cachix.org-1:/W511kfAgRPaUzA3Igf4ahN181qFRl745blhvfQOBio="
    ];
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      tktUtils = pkgs.callPackage ./tkt-utils.nix { };
      inherit (tktUtils) mkTKTForKernels;
    tktPackages  =
        with pkgs;
        mkTKTForKernels [
          linux_6_1
          linux_6_12
          linux_6_6
          linux_6_18
          linux_6_19
        ];

            kernels  = pkgs.lib.filterAttrs (name: value:  pkgs.lib.strings.match "linux_.*" name != null ) tktPackages;
            linuxPackages = pkgs.lib.filterAttrs (name: value:  pkgs.lib.strings.match "linuxPackages.*" name != null ) tktPackages;

        in
    {

    packages.x86_64-linux =  kernels;
    inherit linuxPackages;
    };

}
