#!/bin/sh

# Setup a BSD emulator from scratch
#
# Procedure http://www.netbsd.org/ports/vax/emulator-howto.html
#
# Chris Pinnock Feb/2021 - No Warranty - Use at your own risk!
#
# NetBSD/vax

# CDNs
NETBSDCDN="https://cdn.netbsd.org/pub/NetBSD"

SIMHDIR="/usr/local/Cellar/simh/3.11.1"

SIMH="$SIMHDIR/bin/vax"
KABIN="$SIMHDIR/share/simh/vax/ka655x.bin"

if [ ! -x "$SIMH" ]; then
	echo "$SIMH not installed"
	exit 1
fi

# Defaults
DEBUG=1
OS=NetBSD
ARCH=vax
SIZE=8G
MEMORY=256M
VERS=9.1
IF="net"
TARGET=$HOME/SIMH/$OS
IMAGE="netbsd-disk-$ARCH.img"

ISO=$OS-$VERS-$ARCH.iso
URL="$NETBSDCDN/NetBSD-$VERS/images/$ISO"

mkdir -p $TARGET
cd $TARGET

if [ -f "$ISO" ]; then
  echo "Using existing $ISO file">&2
else
  echo "Downloading $ISO">&2
  echo "curl --location --output \"$ISO\" \"$URL\""
  curl --location --output $ISO "$URL"
fi

echo "-------------------------------"
echo "BOOTING SIMH EMULATOR:"
echo "ISSUE THE COMMAND  boot dua1:"
echo "TO BOOT THE INSTALLER"
echo "-------------------------------"

echo "load -r $KABIN" >netbsd-boot
echo "set cpu 64m" >>netbsd-boot
echo "set rq0 ra92" >>netbsd-boot
echo "at rq0 netbsd.dsk" >>netbsd-boot
echo "set rq1 cdrom" >>netbsd-boot
echo "at rq1 $ISO" >>netbsd-boot
#echo "at xq0 $IF" >>netbsd-boot
echo "boot cpu" >>netbsd-boot

$SIMH netbsd-boot

