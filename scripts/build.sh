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
apt-get install -y locales dialog gcc gcc-8-arm-linux-gnueabihf gawk bison wget patch build-essential u-boot-tools bc vboot-kernel-utils libncurses5-dev g++-arm-linux-gnueabihf flex texinfo unzip help2man libtool-bin python3 git nano kmod pkg-config autogen autopoint gettext libnl-cli-3-dev libssl-dev libelf-dev linux-libc-dev

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

if [ $(arch) = "aarch64" ]; then
  export HOST="arm-linux-gnueabihf"
  export WIFIVERSION=
  export HEADERS="/opt/sysroot/Programs/kernel-aarch64/3.18.0-19095-g86596f58eadf/headers"
  export FLOAT="--with-float=hard"
  wget -O /opt/kernel.tar.gz https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/86596f58eadf.tar.gz
  tar xfv /opt/kernel.tar.gz -C /opt/kernel
  rm -f /opt/kernel.tar.gz
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
  export HOST="x86_64-linux-gnu"
  export WIFIVERSION=
  export HEADERS="/opt/sysroot/Programs/kernel-amd64/5.2.3/headers"
  export FLOAT=""
  wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.2.3.tar.xz
  tar xfv /opt/linux-5.2.3.tar.xz -C /opt/kernel
  rm -f /opt/linux-5.2.3.tar.xz
  cd /opt/kernel/linux-5.2.3
  #patch -p1 < /opt/PowerOS/patches/linux-3.18-log2.patch
  #patch -p1 < /opt/PowerOS/patches/linux-3.18-hide-legacy-dirs.patch
  #cp include/linux/compiler-gcc5.h include/linux/compiler-gcc8.h
  cp /opt/system/config/config.kernel ./.config
  cp /opt/wireless-regdb/db.txt ./net/wireless
  make oldconfig
  make prepare
  make -j$(nproc)

  make INSTALL_MOD_PATH="/tmp/modules" modules_install
  rm -f /tmp/modules/lib/modules/*/{source,build}
  mkdir -p /opt/sysroot/Programs/kernel-amd64/5.2.3/modules
  cp -rv /tmp/modules/lib/modules/5.2.3/* /opt/sysroot/Programs/kernel-amd64/5.2.3/modules
  ln -s 5.2.3 /opt/sysroot/Programs/kernel-amd64/current
  ln -s /Programs/kernel-amd64/5.2.3/modules /opt/sysroot/System/Kernel/Modules/5.2.3
  rm -rf /tmp/modules

  mkdir -p /opt/sysroot/Programs/kernel-amd64/5.2.3/image
  cp /opt/kernel/linux-5.2.3/arch/x86/boot/bzImage /opt/sysroot/Programs/kernel-amd64/5.2.3/image
  ln -s /Programs/kernel-amd64/current/image /opt/sysroot/System/Kernel/Image

  make headers_check
  make INSTALL_HDR_PATH="/tmp/headers" headers_install
  mkdir -p /opt/sysroot/Programs/kernel-amd64/5.2.3/headers
  cp -rv /tmp/headers/include/* /opt/sysroot/Programs/kernel-amd64/5.2.3/headers
  rm -fr /tmp/headers
  find /opt/sysroot/Programs/kernel-amd64/5.2.3/headers \( -name .install -o -name ..install.cmd \) -delete

  link_files /System/Index/Includes /Programs/kernel-amd64/5.2.3/headers  
fi

rm -rf /opt/kernel

#BUSYBOX:
cd /opt
wget https://busybox.net/downloads/busybox-1.30.1.tar.bz2
tar xfv busybox-1.30.1.tar.bz2
rm -f busybox-1.30.1.tar.bz2
cd busybox-1.30.1
cp /opt/system/config/config.busybox .config

if [ $(arch) = "aarch64" ]; then
  export ARCH=arm
  export CROSS_COMPILE=arm-linux-gnueabihf-  
  echo 'CONFIG_CROSS_COMPILER_PREFIX="arm-linux-gnueabihf-"' >> .config
fi

make -j$(nproc)
make install
mkdir -p /opt/sysroot/Programs/busybox/1.30.1/bin
ln -s 1.30.1 /opt/sysroot/Programs/busybox/current
cp /tmp/busybox/bin/busybox /opt/sysroot/Programs/busybox/1.30.1/bin
#find /tmp/busybox/bin/* -type l -execdir ln -s /Programs/busybox/1.30.1/bin/busybox /opt/sysroot/System/Index/Binaries/{} ';'
#find /tmp/busybox/sbin/* -type l -execdir ln -s /Programs/busybox/1.30.1/bin/busybox /opt/sysroot/System/Index/Binaries/{} ';'
find /tmp/busybox/bin/* -type l -execdir ln -s busybox /opt/sysroot/Programs/busybox/1.30.1/bin/{} ';'
find /tmp/busybox/sbin/* -type l -execdir ln -s busybox /opt/sysroot/Programs/busybox/1.30.1/bin/{} ';'
rm -fr /tmp/busybox

link_files /System/Index/Binaries /Programs/busybox/1.30.1/bin

rm -rf /opt/busybox-1.30.1

#GLIBC
cd /opt
wget https://mirrors.dotsrc.org/gnu/glibc/glibc-2.29.tar.xz
tar xfv glibc-2.29.tar.xz
rm -f glibc-2.29.tar.xz
cd glibc-2.29
mkdir build
cd build

../configure \
  --host=$HOST \
  --prefix= \
  --includedir=/include \
  --libexecdir=/libexec \
  --with-__thread \
  --with-tls \
  --with-fp \
  --with-headers=$HEADERS \
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

rm -rf /opt/glibc-2.29

#BINUTILS
cd /opt
wget https://mirrors.dotsrc.org/gnu/binutils/binutils-2.32.tar.xz
tar xfv binutils-2.32.tar.xz
rm -f binutils-2.32.tar.xz
cd binutils-2.32

./configure \
  --host=$HOST \
  --prefix=/ \
  --with-sysroot=/ \
  --disable-werror \
  --disable-multilib \
  --disable-sim \
  --disable-gdb \
  --disable-nls \
  --disable-static \
  --enable-ld=default \
  --enable-gold=yes \
  --enable-threads \
  --enable-plugins $FLOAT
  
make tooldir=/ -j$(nproc)
make tooldir=/ install DESTDIR=/opt/sysroot/Programs/binutils/2.32
rm -rf /opt/sysroot/Programs/binutils/2.32/{share,lib/ldscripts}
ln -s 2.32 /opt/sysroot/Programs/binutils/current

link_files /System/Index/Binaries /Programs/binutils/2.32/bin
link_files /System/Index/Includes /Programs/binutils/2.32/include
link_files /System/Index/Libraries /Programs/binutils/2.32/lib

rm -rf /opt/binutils-2.32

#GCC
cd /opt
wget ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-8.3.0/gcc-8.3.0.tar.xz
tar xfv gcc-8.3.0.tar.xz
rm -f gcc-8.3.0.tar.xz
cd gcc-8.3.0
./contrib/download_prerequisites
mkdir build
cd build

../configure \
  --host=$HOST \
  --target=$HOST \
  --with-sysroot=/ \
  --prefix=/ \
  --enable-threads=posix \
  --enable-languages=c,c++ \
  --enable-__cxa_atexit \
  --disable-libmudflap \
  --disable-libssp \
  --disable-libgomp \
  --disable-libstdcxx-pch \
  --disable-nls \
  --disable-multilib \
  --disable-libquadmath \
  --disable-libquadmath-support \
  --disable-libsanitizer \
  --disable-libmpx \
  --disable-gold \
  --enable-long-long \
  --disable-static $FLOAT

make -j$(nproc)
make install DESTDIR=/opt/sysroot/Programs/gcc/8.3.0
rm -rf /opt/sysroot/Programs/gcc/8.3.0/share
ln -s 8.3.0 /opt/sysroot/Programs/gcc/current

if [ $(arch) = "aarch64" ]; then
  ln -s arm-linux-gnueabihf-gcc /opt/sysroot/Programs/gcc/8.3.0/bin/cc
fi

link_files /System/Index/Binaries /Programs/gcc/8.3.0/bin
link_files /System/Index/Includes /Programs/gcc/8.3.0/include
link_files /System/Index/Libraries /Programs/gcc/8.3.0/lib
link_files /System/Index/Libraries/libexec /Programs/gcc/8.3.0/libexec

rm -rf /opt/gcc-8.3.0

#make
cd /opt
wget http://ftp.twaren.net/Unix/GNU/gnu/make/make-4.2.1.tar.gz
tar xfv make-4.2.1.tar.gz
rm -f make-4.2.1.tar.gz
cd make-4.2.1
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure \
  --prefix=/ \
  --host=$HOST

make -j$(nproc)
make install DESTDIR=/opt/sysroot/Programs/make/4.2.1
ln -s 4.2.1 /opt/sysroot/Programs/make/current
rm -rf /opt/sysroot/Programs/make/4.2.1/share

link_files /System/Index/Binaries /Programs/make/4.2.1/bin
link_files /System/Index/Includes /Programs/make/4.2.1/include

rm -rf /opt/make-4.2.1

#blazeos
cd /opt
git clone https://github.com/blazeos/packages.git /opt/sysroot/Programs/blazeos

link_files /System/Index/Binaries /Programs/blazeos/bin

if [ $(arch) = "aarch64" ]; then
  #gobohide (0.14 64bit)
  cd /opt
  wget https://gobolinux.org/older_downloads/GoboHide-0.14.tar.bz2
  tar xfv GoboHide-0.14.tar.bz2
  rm -f GoboHide-0.14.tar.bz2
  cd GoboHide-0.14
  wget -O config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
  wget -O config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
  ./configure \
    LDFLAGS="-static" \
    --host=aarch64-linux-gnu \
    --prefix=/
  make -j$(nproc)
  make install DESTDIR=/opt/sysroot/Programs/gobohide/0.14
  ln -s 0.14 /opt/sysroot/Programs/gobohide/current
  rm -rf /opt/sysroot/Programs/gobohide/0.14/{etc,share}

  link_files /System/Index/Binaries /Programs/gobohide/0.14/bin
  
  rm -rf /opt/GoboHide-0.14
fi

#m4
cd /opt
wget https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz
tar xfv m4-1.4.18.tar.xz
rm -f m4-1.4.18.tar.xz
cd m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure \
  --host=$HOST \
  --prefix=/

make -j$(nproc)
make install DESTDIR=/opt/sysroot/Programs/m4/1.4.18
ln -s 1.4.18 /opt/sysroot/Programs/m4/current
rm -rf /opt/sysroot/Programs/m4/1.4.18/share

link_files /System/Index/Binaries /Programs/m4/1.4.18/bin

#STRIP BINARIES
find /opt/sysroot/Programs/*/current/bin -executable -type f | xargs arm-linux-gnueabihf-strip -s || true
find /opt/sysroot/Programs/*/current/sbin -executable -type f | xargs arm-linux-gnueabihf-strip -s || true
find /opt/sysroot/Programs/*/current/libexec -executable -type f | xargs arm-linux-gnueabihf-strip -s || true
