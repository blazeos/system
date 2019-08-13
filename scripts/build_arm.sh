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

