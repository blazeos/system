#!/bin/sh

#CONFIRMED WORKING ON DEBIAN 10 BUSTER

#INSTALL NEEDED PACKAGES
apt-get update
apt-get install -y qemu qemu-user-static binfmt-support debootstrap git

#CREATE CHROOT ENVIRONMENT
cd /opt
if [ -d "/opt/debian-x86_64" ]; then
  git -C /opt/debian-x86_64/opt/system pull
else
  qemu-debootstrap --arch=x86_64 --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
  --variant=buildd --exclude=debfoster buster debian-x86_64 http://ftp.debian.org/debian

  git clone https://github.com/blazeos/system.git /opt/debian-x86_64/opt/system
fi

chroot /opt/debian-x86_64 "/opt/system/scripts/build.sh"

git clone https://github.com/blazeos/system.git /opt/debian-x86_64/opt/sysroot/Users/root/system

cd /opt/debian-x86_64/opt/sysroot
mount -t proc proc System/Kernel/Status/
mount --rbind /sys System/Kernel/Hardware/
mount --rbind /dev dev/

chroot /opt/debian-x86_64/opt/sysroot "/Users/root/system/scripts/build_chroot.sh"

cd /opt/debian-x86_64/opt/sysroot
umount System/Kernel/Status/
umount System/Kernel/Hardware/
umount dev/

rm -rf /opt/debian-x86_64/opt/sysroot/Users/root/system
rm -rf /opt/debian-x86_64/opt/sysroot/Programs/blazeos/cache/*

#pack the sysroot for distribution
