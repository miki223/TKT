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
    nix-filter .url = "github:numtide/nix-filter";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };


  outputs = { self, nixpkgs,... }: {


    packages.x86_64-linux   =  with  nixpkgs.legacyPackages.x86_64-linux;  {
    linux_6_15-tkt  =   callPackage  ./tkt.nix {
    linux = linux_6_15;
    };
     linux_6_15-tkt-clang  =   callPackage  ./tkt.nix {
    linux = linux_6_15;
    stdenv = clangStdenv;
    };
    linux_6_16-tkt  =   callPackage  ./tkt.nix {
    linux = linux_6_16;
    };
     linux_6_16-tkt-clang  =   callPackage  ./tkt.nix {
    linux = linux_6_16;
    stdenv = clangStdenv;
    };
    linuxPackages_6_16-tkt =  linuxPackagesFor self.packages.x86_64-linux.linux_6_16-tkt;
    linuxPackages_6_16-tkt_clang =  linuxPackagesFor self.packages.x86_64-linux.linux_6_16-tkt-clang;
    linuxPackages_6_15-tkt =  linuxPackagesFor self.packages.x86_64-linux.linux_6_15-tkt;
    linuxPackages_6_15-tkt_clang =  linuxPackagesFor self.packages.x86_64-linux.linux_6_15-tkt-clang;

    };

    } ;


}
