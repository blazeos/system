#!/bin/sh
set -e
set -x

#CONFIRMED WORKING ON DEBIAN 10 BUSTER

#INSTALL NEEDED PACKAGES
apt-get update
apt-get install -y qemu qemu-user-static binfmt-support debootstrap git

#CREATE CHROOT ENVIRONMENT
cd /opt
if [ -d "/opt/debian-aarch64" ]; then
  git -C /opt/debian-aarch64/opt/system pull
else
  qemu-debootstrap --arch=arm64 --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
  --variant=buildd --exclude=debfoster buster debian-aarch64 http://ftp.debian.org/debian

  git clone https://github.com/blazeos/system.git /opt/debian-aarch64/opt/system
fi

chroot /opt/debian-aarch64 "/opt/system/scripts/build.sh"

git clone https://github.com/blazeos/system.git /opt/debian-aarch64/opt/sysroot/Users/root/system

cd /opt/debian-aarch64/opt/sysroot
mount -t proc none proc
mount -o bind /dev dev

chroot /opt/debian-aarch64/opt/sysroot "/Users/root/system/scripts/build_chroot.sh"

cd /opt/debian-aarch64/opt/sysroot
umount -l System/Kernel/Status/
umount -l dev/

rm -rf /opt/debian-aarch64/opt/sysroot/Users/root/system
rm -rf /opt/debian-aarch64/opt/sysroot/Programs/blazeos/cache/*

#pack the sysroot for distribution
