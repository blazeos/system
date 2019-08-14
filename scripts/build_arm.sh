#!/bin/sh
set -e
set -x

#FETCH NEEDED TOOLS
apt-get install -y gcc gcc-5-arm-linux-gnueabihf gawk bison wget patch build-essential u-boot-tools bc libncurses5-dev g++-arm-linux-gnueabihf flex texinfo unzip help2man libtool-bin python3 git nano kmod pkg-config autogen autopoint gettext libnl-cli-3-dev

#CREATE DIR STRUCTURE
rm -fr /opt/sysroot
cp -rv /opt/PowerOS/sysroot /opt

#GET WIFI RULES DATABASE
cd /opt
git clone git://git.kernel.org/pub/scm/linux/kernel/git/linville/wireless-regdb.git

#KERNEL
cd /opt
export WIFIVERSION=
wget -O /opt/kernel.tar.gz https://chromium.googlesource.com/chromiumos/third_party/kernel/+archive/86596f58eadf.tar.gz
mkdir /opt/kernel
tar xfv /opt/kernel.tar.gz -C /opt/kernel
cd /opt/kernel
patch -p1 < /opt/system/patches/linux-3.18-log2.patch
patch -p1 < /opt/system/patches/linux-3.18-hide-legacy-dirs.patch
cat /opt/system/config/config.chromeos /opt/system/config/config.chromeos.extra > .config
cp /opt/wireless-regdb/db.txt /opt/kernel/net/wireless
make oldconfig
make prepare
make -j$(nproc) Image
make -j$(nproc) modules
make dtbs
make -j$(nproc)
