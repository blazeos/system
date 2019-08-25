#!/bin/sh
set -e
set -x

blaze install perl
blaze install flex
blaze install bison
blaze install zlib
blaze install openssl
blaze install ca-certificates
blaze install pkg-config
blaze install libnl
blaze install iw
blaze install ncurses
blaze install curl
blaze install tcl
blaze install gettext
blaze install git
blaze install wpa_supplicant

if [ ! $(arch) = "aarch64" ]; then
  blaze install autoconf
  blaze install automake
  blaze install gobohide 1.3
  blaze install libffi
  blaze install expat
  blaze install python3
  blaze install grub2
fi
