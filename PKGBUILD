# Based on the file created for Arch Linux by:
# Tobias Powalowski <tpowa@archlinux.org>
# Thomas Baechler <thomas@archlinux.org>

# Original Contributor: Tk-Glitch <ti3nou at gmail dot com>
# Original Contributor: Hyper-KVM <hyperkvmx86 at gmail dot com>

# All credits due to the previous pioneers of this script whom came before me. Thank you for your effort.
# Hijacked by: ETJAKEOC <etjakeoc@gmail.com>

pkgdesc='A customized Linux kernel install script, forked from the TKG script, aimed at a more performant tune, at the risk of stability.'
arch=('x86_64') # no i686 in here
url="https://www.kernel.org/"
license=('GPL2')
makedepends=(base-devel bc bison coreutils cpio docbook-xsl flex git \
graphviz imagemagick inetutils initramfs kmod libelf pahole \
patchutils perl python-sphinx python-sphinx_rtd_theme schedtool sudo \
tar wget xmlto xz)
if [[ "$_compiler_name" =~ llvm ]]; then
  makedepends+=(llvm clang lld)
elif [[ "$_compiler_name" =~ gcc ]]; then
  makedepends+=(gcc)
fi
optdepends=('schedtool')
options=('!strip')

 # track basedir as different Arch based distros are moving srcdir around
_where="$PWD"

# Create logs dir if it does not already exist
[ -d "$_where/logs" ] || mkdir -p "$_where/logs"


if [ -n "$FAKEROOTKEY" ]; then
  echo "Sourcing 'TKT_CONFIG' file"
else
  rm -f "$_where"/TKT_CONFIG
  if [ "$_IS_GHCI" = "true" ]; then
    msg2 "Overriding config options for GHCI build"
    source "/GHCI.cfg"
    # Save GHCI.cfg contents directly to TKT_CONFIG, no external overrides
    cp /GHCI.cfg "$_where"/TKT_CONFIG
  else
    cp "$_where"/customization.cfg "$_where"/TKT_CONFIG

    # extract _EXT_CONFIG_PATH from customization.cfg only if not GHCI
    if [[ -z "$_EXT_CONFIG_PATH" ]]; then
      eval `grep _EXT_CONFIG_PATH "$_where"/customization.cfg`
    fi

    # Only append external config if path exists
    if [ -f "$_EXT_CONFIG_PATH" ]; then
      msg2 "External configuration file $_EXT_CONFIG_PATH will be used and will override customization.cfg values."
      cat "$_EXT_CONFIG_PATH" >> "$_where"/TKT_CONFIG
    fi
  fi
  declare -p -x >> "$_where"/TKT_CONFIG
  echo -e "_ispkgbuild=\"true\"\n_distro=\"Arch\"\n_where=\"$PWD\"" >> "$_where"/TKT_CONFIG
  # Run user prompts here
  source "$_where"/TKT_CONFIG
  source "$_where"/kconfigs/prepare
  _tkg_initscript
fi

prepare() {
  source "$_where"/TKT_CONFIG
  source "$_where"/kconfigs/prepare
  rm -rf $pkgdir # Nuke the entire pkg folder so it'll get regenerated clean on next build
  ln -s "${_kernel_work_folder_abs}" "${srcdir}/linux-src-git"
  _tkg_srcprep
}

source "$_where"/TKT_CONFIG

if [ -z "$_kernel_localversion" ]; then
    # Set the kernel name TKT style
    _diet_tag=""
    _modprobed_tag=""
    _rt_tag=""
    _compiler_name=""

    [ "$_kernel_on_diet" = "true" ] && _diet_tag="diet"
    [ "$_modprobeddb" = "true" ] && _modprobed_tag="modprobed"
    [ "$_preempt_rt" = "1" ] && _rt_tag="rt"

    if [ "$_compiler" = "llvm" ]; then
      _compiler_name="-llvm"
      _package_compiler="llvm"
    else
      _compiler_name="-gcc"
      _package_compiler="gcc"
    fi

    # Start parts array
    parts=( "tkt" )

    # Append distro to kernel name
    shopt -s nocasematch
    parts+=( "$(echo "$_distro" | tr '[:upper:]' '[:lower:]')" )
    shopt -u nocasematch

    # Append tags to kernel name as needed
    [ -n "$_diet_tag" ] && parts+=( "$_diet_tag" )
    [ -n "$_modprobed_tag" ] && parts+=( "$_modprobed_tag" )
    parts+=( "$_cpusched" )
    [ -n "$_rt_tag" ] && parts+=( "$_rt_tag" )
    parts+=( "$_package_compiler" )

    _kernel_flavor=$(IFS=- ; echo "${parts[*]}")
    {
      echo "_diet_tag=$_diet_tag"
      echo "_modprobed_tag=$_modprobed_tag"
      echo "_rt_tag=$_rt_tag"
      echo "_compiler_name=$_package_compiler"
      echo "_cpusched=$_cpusched"
      echo "_kernel_flavor=$_kernel_flavor"
    } >> "$_where/TKT_CONFIG"
else
    _kernel_flavor="tkt-${_kernel_localversion}"
fi

# Setup kernel_subver variable
if [[ "$_sub" = rc* ]]; then
    # if an RC version, subver will always be 0
    _kernel_subver=0
else
    _kernel_subver="${_sub}"
fi

# Generate kernel name with the required information
_kernelname="${_basekernel}.${_sub}-${_kernel_flavor}"
echo "_kernelname=$_kernelname" >> "$_where/TKT_CONFIG"

if [ -n "$_custom_pkgbase" ]; then
    pkgbase="${_custom_pkgbase}"
    echo "pkgbase=$pkgbase" >> "$_where/TKT_CONFIG"
else
    pkgbase="linux-${_kernelname}"
    echo "pkgbase=$pkgbase" >> "$_where/TKT_CONFIG"
fi

source "$_where"/TKT_CONFIG

# Define the final package variables for makepkg
pkgname=("${pkgbase}" "${pkgbase}-headers")
pkgver="${_basekernel}"."${_sub}"
pkgrel=1

for f in "$_where"/kconfigs/"$_basekernel"/* "$_where"/kpatches/"$_basekernel"/*; do
  source+=( "$f" )
  sha256sums+=( "SKIP" )
done

export KBUILD_BUILD_HOST=archlinux
export KBUILD_BUILD_USER=$pkgbase
export KBUILD_BUILD_TIMESTAMP="$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})"

build() {
  source "$_where"/TKT_CONFIG
  cd "$_kernel_work_folder_abs"

  # Use user specified compiler path if set
  if [[ "$_compiler_name" =~ llvm ]] && [ -n "${CUSTOM_LLVM_PATH}" ]; then
    PATH="${CUSTOM_LLVM_PATH}/bin:${CUSTOM_LLVM_PATH}/lib:${CUSTOM_LLVM_PATH}/include:${PATH}"
  fi
  if [[ "$_compiler_name" =~ gcc ]] && [ -n "${CUSTOM_GCC_PATH}" ]; then
    PATH="${CUSTOM_GCC_PATH}/bin:${CUSTOM_GCC_PATH}/lib:${CUSTOM_GCC_PATH}/include:${PATH}"
  fi

  # Guard Clause: Exit early if the compiler is not supported
  if [[ ! "$_compiler_name" =~ (llvm|gcc) ]]; then
    msg2 "Fatal error: Unsupported compiler '${_compiler_name}'. Bailing out."
    exit 1
  fi

  # SUGGESTION: Renamed variable for clarity and used modern command substitution
  local _make_jobs_arg
  if [ "$_force_all_threads" = "true" ]; then
    _make_jobs_arg="-j$(nproc)"
  else
    _make_jobs_arg="${MAKEFLAGS}"
  fi

  # ccache
  if [ "$_noccache" != "true" ] && pacman -Qq ccache &> /dev/null; then
    export PATH="/usr/lib/ccache/bin/:$PATH"
    export CCACHE_SLOPPINESS="file_macro,locale,time_macros"
    export CCACHE_NOHASHDIR="true"
    msg2 'ccache was found and will be used'
  fi

  # document the TKT variables
  declare -p | cut -d ' ' -f 3 | grep -P '^_(?!=|EXT_CONFIG_PATH|where|path)' > "${srcdir}/customization-full.cfg"

  # remove -O2 flag and place user optimization flag
  CFLAGS=${CFLAGS/-O2/}
  CFLAGS+=" ${_compileropt}"
  export KCPPFLAGS KCFLAGS

  if pacman -Qq schedtool &> /dev/null; then
    msg2 "Using schedtool to set scheduling policy for the build."
    local _pid="$$"
    command schedtool -B -n 1 "$_pid" || :
    command ionice -n 1 -p "$_pid" || :
  fi

  # --- Build execution ---
  local diet_args=""
  local diet_target=""

  if [[ "$_modprobeddb" == "true" || "$_kernel_on_diet" == "true" ]]; then
    msg2 "Building modprobed/diet kernel with ${_compiler_name^^}..."
    diet_args="LMC_KEEP=false LMC_FILE=='${_modprobeddb_db_path}'"
    diet_target="localmodconfig"
  else
    msg2 "Building generic kernel with ${_compiler_name^^}..."
  fi

  {
    time (env ${compiler_opt} make "${_make_jobs_arg}" ${diet_args} ${diet_target} bzImage modules)
  } 3>&1 1>&2 2>&3
}

hackbase() {
  source "$_where"/TKT_CONFIG

  pkgdesc="The $pkgdesc kernel and modules"
  depends=('coreutils' 'kmod' 'initramfs')
  optdepends=('linux-docs: Kernel hackers manual - HTML documentation that comes with the Linux kernel.'
              'crda: to set the correct wireless channels of your country.'
              'linux-firmware: Firmware files for Linux'
              'modprobed-db: Keeps track of EVERY kernel module that has ever been probed. Useful for make localmodconfig.'
              'nvidia-tkg: NVIDIA drivers for all installed kernels - non-dkms version. From TK-Glitch.'
              'nvidia-dkms-tkg: NVIDIA drivers for all installed kernels - dkms version. From TK-Glitch.'
              'update-grub: Simple wrapper around grub-mkconfig.')
  if [ -e "${srcdir}/ntsync.rules" ]; then
    provides=("linux=${pkgver}-${_kernelname}" "${pkgbase}" VIRTUALBOX-GUEST-MODULES WIREGUARD-MODULE NTSYNC-MODULE ntsync-header)
  else
    provides=("linux=${pkgver}-${_kernelname}" "${pkgbase}" VIRTUALBOX-GUEST-MODULES WIREGUARD-MODULE)
  fi
  replaces=(virtualbox-guest-modules-arch wireguard-arch)

  cd "$_kernel_work_folder_abs"

  # Get kernel version
  local _kernver="$(<version)"
  local modulesdir="$pkgdir/usr/lib/modules/$_kernver"

  msg2 "Installing boot image..."
  # Systemd expects to find the kernel here to allow hibernation
  install -Dm644 "$(make ${llvm_opt} -s image_name)" "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  echo "$pkgbase" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  msg2 "Installing modules..."

  local _STRIP_MODS=""
  [[ "$_STRIP" == "true" ]] && _STRIP_MODS="INSTALL_MOD_STRIP=1"

  ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$pkgdir/usr" $_STRIP_MODS \
    DEPMOD=/doesnt/exist modules_install  # Suppress depmod

  # Remove build and source links
  rm -f "$modulesdir"/{source,build}

  # Install cleanup pacman hook and script
  sed -e "s|cleanup|${pkgbase}-cleanup|g" "${srcdir}"/90-cleanup.hook |
    install -Dm644 /dev/stdin "${pkgdir}/usr/share/libalpm/hooks/90-${pkgbase}.hook"
  install -Dm755 "${srcdir}"/cleanup "${pkgdir}/usr/share/libalpm/scripts/${pkgbase}-cleanup"

  # Install customization file, for reference
  install -Dm644 "${srcdir}"/customization-full.cfg "${pkgdir}/usr/share/doc/${pkgbase}/customization.cfg"

  # ntsync
  if [ -e "${srcdir}/ntsync.conf" ]; then
    # Load ntsync module at boot
    msg2 "Set the ntsync module to be loaded at boot through /etc/modules-load.d"
    install -Dm644 "${srcdir}"/ntsync.conf "${pkgdir}/etc/modules-load.d/ntsync-${pkgbase}.conf"
  fi

  # Install udev rule for ntsync if needed (<6.14)
  if [ -e "${srcdir}/ntsync.rules" ]; then
    msg2 "Installing udev rule for ntsync"
    install -Dm644 "${srcdir}"/ntsync.rules "${pkgdir}/etc/udev/rules.d/ntsync.rules"
  fi
}

_ukify() {
  # Check if the installed kernel is a UKI and update mkinitcpio preset
  msg2 "Checking if the installed kernel is a Unified Kernel Image (UKI)..."
  if _is_uki "$modulesdir/vmlinuz"; then
    msg2 "Unified Kernel Image detected, updating mkinitcpio preset..."

    # Create or update the mkinitcpio preset file
    local preset_file="${pkgdir}/etc/mkinitcpio.d/${pkgbase}.preset"
    mkdir -p "${pkgdir}/etc/mkinitcpio.d"

    # Write a UKI-compatible preset
    cat > "$preset_file" <<EOF
# mkinitcpio preset file for ${pkgbase} (UKI configuration)

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="${_kernver}"
PRESETS=('default')

default_image="/boot/${pkgbase}.efi"
default_uki="/boot/${pkgbase}.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
EOF

    msg2 "Updated mkinitcpio preset file at ${preset_file} for UKI"
  else
    msg2 "No Unified Kernel Image detected, using standard preset configuration..."

    # Create a standard preset file (if needed)
    local preset_file="${pkgdir}/etc/mkinitcpio.d/${pkgbase}.preset"
    mkdir -p "${pkgdir}/etc/mkinitcpio.d"

    cat > "$preset_file" <<EOF
# mkinitcpio preset file for ${pkgbase}

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="${_kernver}"
PRESETS=('default')

default_image="/boot/vmlinuz-${pkgbase}"
default_initramfs="/boot/initramfs-${pkgbase}.img"
default_options=""
EOF

    msg2 "Created standard mkinitcpio preset file at ${preset_file}"
  fi
}

hackheaders() {
  source "$_where"/TKT_CONFIG

  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  provides=("linux-headers=${pkgver}-${_kernelname}" "${pkgbase}-headers=${pkgver}-${_kernelname}")

  cd "$_kernel_work_folder_abs"

  local builddir="${pkgdir}/usr/lib/modules/$(<version)/build"

  msg2 "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
  cp -t "$builddir" -a scripts

  # add objtool for external module building and enabled VALIDATION_STACK option
  install -Dt "$builddir/tools/objtool" tools/objtool/objtool

  # add xfs and shmem for aufs building
  mkdir -p "$builddir"/{fs/xfs,mm}

  # add resolve_btfids on 6.x
  if [[ $_basever = 6* ]]; then
    install -Dt "$builddir"/tools/bpf/resolve_btfids tools/bpf/resolve_btfids/resolve_btfids || ( warning "$builddir/tools/bpf/resolve_btfids was not found. This is undesirable and might break dkms modules !!! Please review your config changes and consider using the provided defconfig and tweaks without further modification." && read -rp "Press enter to continue anyway" )
  fi

  msg2 "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/x86" -a arch/x86/include
  install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # http://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # http://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  msg2 "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  msg2 "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */x86/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  msg2 "Removing documentation..."
  rm -r "$builddir/Documentation"

  msg2 "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  msg2 "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  msg2 "Stripping build tools..."
  local file
  while read -rd '' file; do
    if [[ "$_compiler_name" =~ llvm ]] || [[ "$_compiler_name" =~ clang ]]; then
      case "$(file -Sib "$file")" in
        application/x-sharedlib\;*)      # Libraries (.so)
          llvm-strip --strip-all-gnu $STRIP_SHARED "$file" ;;
        application/x-archive\;*)        # Libraries (.a)
          llvm-strip --strip-all-gnu $STRIP_STATIC "$file" ;;
        application/x-executable\;*)     # Binaries
          llvm-strip --strip-all-gnu $STRIP_BINARIES "$file" ;;
        application/x-pie-executable\;*) # Relocatable binaries
          llvm-strip --strip-all-gnu $STRIP_SHARED "$file" ;;
      esac
    elif [[ "$_compiler_name" =~ gcc ]]; then
      case "$(file -Sib "$file")" in
        application/x-sharedlib\;*)      # Libraries (.so)
          strip --strip-all $STRIP_SHARED "$file" ;;
        application/x-archive\;*)        # Libraries (.a)
          strip --strip-all $STRIP_STATIC "$file" ;;
        application/x-executable\;*)     # Binaries
          strip --strip-all $STRIP_BINARIES "$file" ;;
        application/x-pie-executable\;*) # Relocatable binaries
          strip --strip-all $STRIP_SHARED "$file" ;;
      esac
    fi
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  msg2 "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"

  if [ "$_STRIP" = "true" ]; then
    if [[ "$_compiler_name" =~ llvm ]]; then
      echo "Stripping vmlinux..."
      llvm-strip --strip-all-gnu $STRIP_STATIC "$builddir/vmlinux"
    elif [[ "$_compiler_name" =~ gcc ]]; then
      echo "Stripping vmlinux..."
      strip --strip-all $STRIP_STATIC "$builddir/vmlinux"
    fi
  fi

  if [ "$_NUKR" = "true" ]; then
    rm -rf "$srcdir" # Nuke the entire src folder so it'll get regenerated clean on next build
  fi
}

source /dev/stdin <<EOF
package_${pkgbase}() {
hackbase
}

package_${pkgbase}-headers() {
hackheaders
}
EOF
