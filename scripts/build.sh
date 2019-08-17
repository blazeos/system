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
git clone git://git.kernel.org/pub/scm/linux/kernel/git/linville/wireless-regdb.git

