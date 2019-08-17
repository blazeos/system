#!/bin/sh

#CONFIRMED WORKING ON DEBIAN 10 BUSTER

#INSTALL NEEDED PACKAGES
apt-get update
apt-get install -y qemu qemu-user-static binfmt-support debootstrap git

#CREATE CHROOT ENVIRONMENT
cd /opt
qemu-debootstrap --arch=arm64 --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
--variant=buildd --exclude=debfoster buster debian-arm64 http://ftp.debian.org/debian

git clone https://github.com/blazeos/system.git /opt/debian-arm64/opt/system
