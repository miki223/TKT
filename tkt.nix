
{ lib, fetchFromGitHub, linuxManualConfig, linux,stdenv , features ? {},kernelPatches ? [],randstructSeed ? "",  tktRepo ? (fetchFromGitHub {
   owner  = "ETJAKEOC";
   repo = "TKT";
    rev =  "1ac91e8";
   sha256 = "X8s++DlAiVCqyBREycedxJQs6TQawoKSCni5Ez4QSVc=";}
   )}:


let

  kversionNoPatch = lib.versions.majorMinor linux.version;
  compiler = {
  name = if stdenv.cc.isGNU then "GCC" else  if stdenv.cc.isClang then "LLVM" else "unknown";
  version = stdenv.cc.version;
  };
in


linuxManualConfig  {
  version = "${linux.version}-tkt";
  allowImportFromDerivation = true;
  configfile = "${tktRepo}/kconfigs/${kversionNoPatch}/config.x86_64";
  inherit (linux) src;
 inherit  stdenv;
 extraMakeFlags = ["LOCALVERSION=-tkt-${compiler.name}_${compiler.version}"];
 kernelPatches = [
        {
        name = "add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER";
        patch =   "${tktRepo}/kpatches/${kversionNoPatch}/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch";
        }
        {
        name = "bore";
        patch  =  "${tktRepo}/kpatches/${kversionNoPatch}/0001-bore.patch";
        }
        {
       name = "clear-patches";
       patch  =  "${tktRepo}/kpatches/${kversionNoPatch}/0002-clear-patches.patch";
        }
        {
        name = "glitched-base ";
        patch  =  "${tktRepo}/kpatches/${kversionNoPatch}/0003-glitched-base.patch";
        }
        {
        name = "glitched-cfs";
        patch = " ${tktRepo}/kpatches/${kversionNoPatch}//0003-glitched-cfs.patch";
        }
        {
        name = "add-acs-overrides_iommu";
        patch = " ${tktRepo}/kpatches/${kversionNoPatch}/0006-add-acs-overrides_iommu.patch";
        }
        {
      name = "0006-add-acs-";
      patch = " ${tktRepo}/kpatches/${kversionNoPatch}//0012-misc-additions.patch";
        }
     {
     name = "OpenRGB";
     patch = "${tktRepo}/kpatches/${kversionNoPatch}//0014-OpenRGB.patch";
     }

  ];




modDirVersion  = "${lib.versions.pad 3 linux.version}-tkt-${compiler.name}_${compiler.version}";
  extraMeta = with lib; {
    description = "TꓘT tuned kernel with custom schedulers, bcachefs, OpenRGB tweaks, and memory tuning.";
    homepage = "https://github.com/ETJAKEOC/TKT";
    license = licenses.gpl2;
    maintainers = [ maintainers.yourHandle ];
    platforms = platforms.linux;

    };
}
