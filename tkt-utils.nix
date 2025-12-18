{
  callPackage,
  lib,
  stdenv,
  clangStdenv,
  linuxPackagesFor,
}:
let
  mkTKT = callPackage ./tkt.nix;
  mkTKTForKernels = kernels: lib.mergeAttrsList (map mkTKTForKernel kernels);
  mkTKTForKernel =
    kernel:
    let
      _major_minor_ersion = lib.replaceString "." "_" (lib.versions.majorMinor kernel.version);
      _nixosPackageFor = kernel: linuxPackagesFor kernel;
      kernels = {
        "linux_${_major_minor_ersion}-tkt" = mkTKT {
          linux = kernel;
          inherit stdenv;
          minimal-modules = true;
        };
        "linux_${_major_minor_ersion}-tkt_clang" = mkTKT {
          linux = kernel;
          stdenv = clangStdenv;
          minimal-modules = true;

        };

      };
    in
    {
      "linux_${_major_minor_ersion}-tkt_clang" = kernels."linux_${_major_minor_ersion}-tkt_clang";
      "linux_${_major_minor_ersion}-tkt" = kernels."linux_${_major_minor_ersion}-tkt";
      "linuxPackages_${_major_minor_ersion}-tkt" =
        linuxPackagesFor
          kernels."linux_${_major_minor_ersion}-tkt";
      "linuxPackages_${_major_minor_ersion}-tkt_clang" =
        linuxPackagesFor
          kernels."linux_${_major_minor_ersion}-tkt_clang";

    };

in
{
  inherit mkTKT;
  inherit mkTKTForKernel;
  inherit mkTKTForKernels;
}
