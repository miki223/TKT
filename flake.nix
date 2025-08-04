{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    tktRepo = {
    url = "path:./.";
   flake = false;
   };
  };


  outputs = { self, nixpkgs,tktRepo,... }: {


    packages.x86_64-linux   =  with  nixpkgs.legacyPackages.x86_64-linux;  {
    linux_6_15-tkt  =   callPackage  ./tkt.nix {
    linux = linux_6_15;
    inherit tktRepo;
    };
     linux_6_15-tkt-clang  =   callPackage  ./tkt.nix {
    linux = linux_6_15;
    stdenv = clangStdenv;
    inherit tktRepo;
    };

    linuxPackages_6_15-tkt =  linuxPackagesFor self.packages.x86_64-linux.linux_6_15-tkt;
    linuxPackages_6_15-tkt_clang =  linuxPackagesFor self.packages.x86_64-linux.linux_6_15-tkt-clang;

    };

    } ;


}
