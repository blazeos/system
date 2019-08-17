#!/bin/sh
set -e
set -x

#FUNCTIONS
link_files () {  
  find /opt/sysroot$2 -mindepth 1 -depth -type d -printf "%P\n" | while read dir; do mkdir -p "/opt/sysroot$1/$dir"; done
  find /opt/sysroot$2 -not -type d -printf "%P\n" | while read file; do ln -s "$2/$file" "/opt/sysroot$1/$file"; done
}

#FETCH NEEDED TOOLS
apt-get update
apt-get install -y locales dialog
apt-get install -y gcc gcc-8-arm-linux-gnueabihf gawk bison wget patch build-essential u-boot-tools bc vboot-kernel-utils libncurses5-dev g++-arm-linux-gnueabihf flex texinfo unzip help2man libtool-bin python3 git nano kmod pkg-config autogen autopoint gettext libnl-cli-3-dev

#CREATE DIR STRUCTURE
rm -fr /opt/sysroot
mkdir /opt/sysroot
cp -rv /opt/system/sysroot/* /opt/sysroot

#GET WIFI RULES DATABASE
cd /opt
rm -rf wireless-regdb
git clone git://git.kernel.org/pub/scm/linux/kernel/git/linville/wireless-regdb.git

#KERNEL
cd /opt
rm -fr kernel
mkdir /opt/kernel

if [ $(arch) == "aarch64" ]; then
  export WIFIVERSION=
  wget -O /opt/kernel.tar.gz https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/86596f58eadf.tar.gz
  tar xfv /opt/kernel.tar.gz -C /opt/kernel
  cd /opt/kernel
  patch -p1 < /opt/system/patches/linux-3.18-log2.patch
  patch -p1 < /opt/system/patches/linux-3.18-hide-legacy-dirs.patch
  cp include/linux/compiler-gcc5.h include/linux/compiler-gcc8.h
  cat /opt/system/config/config.chromeos /opt/system/config/config.chromeos.extra > .config

  make oldconfig
  make prepare
  make -j$(nproc) Image
  make -j$(nproc) modules
  make -j$(nproc) dtbs
  make -j$(nproc)

  make INSTALL_MOD_PATH="/tmp/modules" modules_install
  rm -f /tmp/modules/lib/modules/*/{source,build}
  mkdir -p /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/modules
  cp -rv /tmp/modules/lib/modules/3.18.0-19095-g86596f58eadf/* /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/modules
  ln -s 3.18.0-19095-g86596f58eadf /opt/sysroot/Programs/kernel-aarch64/current
  ln -s /Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/modules /opt/sysroot/System/Kernel/Modules/3.18.0-19095-g86596f58eadf
  rm -rf /tmp/modules
  #depmod -b /opt/sysroot/System/Kernel/Modules -F System.map "3.18.0-19095-g86596f58eadf"

  make INSTALL_DTBS_PATH="/opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/dtbs" dtbs_install

  cp /opt/PowerOS/signing/kernel.its .
  mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
  dd if=/dev/zero of=bootloader.bin bs=512 count=1
  echo "console=tty1 init=/sbin/init root=PARTUUID=%U/PARTNROFF=1 rootwait rw noinitrd" > cmdline
  vbutil_kernel --pack vmlinux.kpart --version 1 --vmlinuz vmlinux.uimg --arch aarch64 --keyblock /opt/PowerOS/signing/kernel.keyblock --signprivate /opt/PowerOS/signing/kernel_data_key.vbprivk --config cmdline --bootloader bootloader.bin
  mkdir -p /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/image
  cp vmlinux.kpart /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/image
  ln -s /Programs/kernel-aarch64/current/image /opt/sysroot/System/Kernel/Image

  make mrproper
  make ARCH=arm headers_check
  make ARCH=arm INSTALL_HDR_PATH="/tmp/headers" headers_install
  mkdir -p /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers
  cp -rv /tmp/headers/include/* /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers
  rm -fr /tmp/headers
  #link headers to include dir??
  find /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers \( -name .install -o -name ..install.cmd \) -delete  
fi

