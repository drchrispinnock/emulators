#!/bin/sh

# Setup or run a BSD emulator from scratch
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
SETUP=0
DEBUG=1
OS=NetBSD
ARCH=vax
SIZE=8G
MEMORY=256M
VERS=9.1
IF="net"
TARGET=$HOME/VM/SIMH/$OS
IMAGE="netbsd-disk-$ARCH.img"

if [ "$1" = "-i" ]; then
	SETUP=1
	shift
fi

ISO=$OS-$VERS-$ARCH.iso
URL="$NETBSDCDN/NetBSD-$VERS/images/$ISO"

mkdir -p $TARGET
cd $TARGET

if [ ! -f "$IMAGE" ]; then
	echo "No disk image - setting up"
	SETUP=1
fi

if [ "$SETUP" = "1" ]; then
	if [ -f "$ISO" ]; then
	  echo "Using existing $ISO file">&2
	else
	  echo "Downloading $ISO">&2
	  echo "curl --location --output \"$ISO\" \"$URL\""
	  curl --location --output $ISO "$URL"
	 fi
fi

echo "-------------------------------"
echo "BOOTING SIMH EMULATOR:"
if [ "$SETUP" = "1" ]; then
	echo "ISSUE THE COMMAND  boot dua1:"
	echo "TO BOOT THE INSTALLER"
else	
	echo "ISSUE THE COMMAND  boot dua0:"
	echo "TO BOOT THE OS"
fi
echo "-------------------------------"

echo "load -r $KABIN" >netbsd-boot
echo "set cpu 64m" >>netbsd-boot
echo "set rq0 ra92" >>netbsd-boot
echo "at rq0 $IMAGE" >>netbsd-boot

if [ "$SETUP" = "1" ]; then
	echo "set rq1 cdrom" >>netbsd-boot
	echo "at rq1 $ISO" >>netbsd-boot
fi
#echo "at xq0 $IF" >>netbsd-boot
echo "boot cpu" >>netbsd-boot

$SIMH netbsd-boot

