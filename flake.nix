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

  outputs = { self, nixpkgs,... }:
  let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  tktUtils = pkgs.callPackage ./tkt-utils.nix {};
  inherit  (tktUtils) mkTKTForKernels;
  in
  {
    packages.x86_64-linux   = with pkgs;  mkTKTForKernels [linux_6_15 linux_6_16 linux_6_1 linux_6_12 linux_6_6];
    } ;


}
