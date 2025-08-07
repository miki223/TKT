{
  description = "A very basic flake";
nixConfig  = {
extra-substitors = [
"httpsL//tkt-cache.cachix.org"

];
  extra-trusted-public-keys = [
  "tkt-cache.cachix.org-1:/W511kfAgRPaUzA3Igf4ahN181qFRl745blhvfQOBio="

  ];
};
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };


  outputs = { self, nixpkgs,... }:
  let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  tktUtils = pkgs.callPackage ./tkt-utils.nix {};
  inherit  (tktUtils) mkTKTForKernels;
  in
  {
    packages.x86_64-linux   = with pkgs;  mkTKTForKernels [linux_6_15 linux_6_16 linux_6_1];
    } ;


}
