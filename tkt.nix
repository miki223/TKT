
{ lib, fetchFromGitHub, linuxManualConfig, linux,stdenv , features ? {},kernelPatches ? [],randstructSeed ? "",withBore ? true,minimal-modules ? true}:



let

  kversionNoPatch = lib.versions.majorMinor linux.version;
  ksources  = with  lib.fileset; toSource {
  root = ./.;
  fileset =( union ./kconfigs/${kversionNoPatch}  ./kpatches/${kversionNoPatch});
  };
  compiler = {
  name = if stdenv.cc.isGNU then "GCC" else  if stdenv.cc.isClang then "LLVM" else "unknown";
  version = stdenv.cc.version;
  };
  patchdir  = "${ksources}/kpatches/${kversionNoPatch}";
  scheduler = if withBore then [
   {
        name = "bore";
        patch  =  "${patchdir}/0001-bore.patch";
        }


  ] else [

     {
        name = "glitched-eevdf-additions" ;
        patch  =  "${patchdir}/0003-glitched-eevdf-additions.patch";
      }
      {
      name = "prjc";
      patch = "${patchdir}/0009-prjc.patch";
      }
  ];

  in


linuxManualConfig  {
  version = "${linux.version}-tkt";
  allowImportFromDerivation = true;
  configfile = "${ksources}/kconfigs/${kversionNoPatch}/config.x86_64";
  inherit (linux) src;
 inherit  stdenv;
 extraMakeFlags = ["LOCALVERSION=-tkt-${compiler.name}_${compiler.version}" ] ++ lib.lists.optionals minimal-modules ["LSMOD=${ksources}/kconfigs/${kversionNoPatch}/minimal-modprobed.db" "localmodconfig"];
 kernelPatches = [
        {
        name = "add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER";
        patch =   "${patchdir}/0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch";
        }

        {
       name = "clear-patches";
       patch  =  "${patchdir}/0002-clear-patches.patch";
        }
        {
        name = "glitched-base ";
        patch  =  "${patchdir}/0003-glitched-base.patch";
        }
        {
        name = "glitched-cfs";
        patch = " ${patchdir}//0003-glitched-cfs.patch";
        }
        {
        name = "add-acs-overrides_iommu";
        patch = " ${patchdir}/0006-add-acs-overrides_iommu.patch";
        }
        {
      name = "0006-add-acs-";
      patch = " ${patchdir}//0012-misc-additions.patch";
        }
     {
     name = "OpenRGB";
     patch = "${patchdir}//0014-OpenRGB.patch";
     }

  ] ++ scheduler;




modDirVersion  = "${lib.versions.pad 3 linux.version}-tkt-${compiler.name}_${compiler.version}";
  extraMeta = with lib; {
    description = "TꓘT tuned kernel with custom schedulers, bcachefs, OpenRGB tweaks, and memory tuning.";
    homepage = "https://github.com/ETJAKEOC/TKT";
    license = licenses.gpl2;
    maintainers = [ maintainers.yourHandle ];
    platforms = platforms.linux;

    };
}
