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
apt-get install -y locales dialog gcc gcc-8-arm-linux-gnueabihf gawk bison wget patch build-essential u-boot-tools bc vboot-kernel-utils libncurses5-dev g++-arm-linux-gnueabihf flex texinfo unzip help2man libtool-bin python3 git nano kmod pkg-config autogen autopoint gettext libnl-cli-3-dev

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

  make INSTALL_DTBS_PATH="/opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/dtbs" dtbs_install

  cp /opt/system/signing/kernel.its .
  mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg
  dd if=/dev/zero of=bootloader.bin bs=512 count=1
  echo "console=tty1 init=/sbin/init root=PARTUUID=%U/PARTNROFF=1 rootwait rw noinitrd" > cmdline
  vbutil_kernel --pack vmlinux.kpart --version 1 --vmlinuz vmlinux.uimg --arch aarch64 --keyblock /opt/system/signing/kernel.keyblock --signprivate /opt/system/signing/kernel_data_key.vbprivk --config cmdline --bootloader bootloader.bin
  mkdir -p /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/image
  cp vmlinux.kpart /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/image
  ln -s /Programs/kernel-aarch64/current/image /opt/sysroot/System/Kernel/Image

  make mrproper
  make ARCH=arm headers_check
  make ARCH=arm INSTALL_HDR_PATH="/tmp/headers" headers_install
  mkdir -p /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers
  cp -rv /tmp/headers/include/* /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers
  rm -fr /tmp/headers
  find /opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers \( -name .install -o -name ..install.cmd \) -delete
  link_files /System/Index/Includes /Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers  
else
  echo "Native build"
fi

#BUSYBOX:
cd /opt
wget https://busybox.net/downloads/busybox-1.30.1.tar.bz2
tar xfv busybox-1.30.1.tar.bz2
cd busybox-1.30.1
cp /opt/system/config/config.busybox .config

if [ $(arch) == "aarch64" ]; then
  export ARCH=arm
  export CROSS_COMPILE=arm-linux-gnueabihf-  
  echo 'CONFIG_CROSS_COMPILER_PREFIX="arm-linux-gnueabihf-"' >> .config
fi

make -j$(nproc)
make install
mkdir -p /opt/sysroot/Programs/busybox/1.30.1/bin
ln -s 1.30.1 /opt/sysroot/Programs/busybox/current
cp /tmp/busybox/bin/busybox /opt/sysroot/Programs/busybox/1.30.1/bin
find /tmp/busybox/bin/* -type l -execdir ln -s /Programs/busybox/1.30.1/bin/busybox /opt/sysroot/System/Index/Binaries/{} ';'
find /tmp/busybox/sbin/* -type l -execdir ln -s /Programs/busybox/1.30.1/bin/busybox /opt/sysroot/System/Index/Binaries/{} ';'
rm -fr /tmp/busybox

#GLIBC
cd /opt
wget https://mirrors.dotsrc.org/gnu/glibc/glibc-2.29.tar.xz
tar xfv glibc-2.29.tar.xz
cd glibc-2.29
mkdir build
cd build

../configure \
  --host=arm-linux-gnueabihf \
  --prefix= \
  --includedir=/include \
  --libexecdir=/libexec \
  --with-__thread \
  --with-tls \
  --with-fp \
  --with-headers=/opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers \
  --without-cvs \
  --without-gd \
  --enable-kernel=3.18.0 \
  --enable-stack-protector=strong \
  --enable-shared \
  --enable-add-ons=no \
  --enable-obsolete-rpc \
  --disable-profile \
  --disable-debug \
  --disable-sanity-checks \
  --disable-static \
  --disable-werror

make -j$(nproc)
make install DESTDIR=/opt/sysroot/Programs/glibc/2.29
rm -rf /opt/sysroot/Programs/glibc/2.29/{libexec,share,var}
ln -s 2.29 /opt/sysroot/Programs/glibc/current
cp /opt/sysroot/Programs/glibc/2.29/etc/* /opt/sysroot/System/Settings
rm -rf /opt/sysroot/Programs/glibc/2.29/etc

link_files /System/Index/Binaries /Programs/glibc/2.29/bin
link_files /System/Index/Includes /Programs/glibc/2.29/include
link_files /System/Index/Libraries /Programs/glibc/2.29/lib
link_files /System/Index/Binaries /Programs/glibc/2.29/sbin