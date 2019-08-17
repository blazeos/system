#!/bin/sh

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

chroot /opt/debian-aarch64 "/opt/system/script/build.sh"
