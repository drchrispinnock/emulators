#!/bin/sh

# Setup a NetBSD emulator from scratch

ARCH=amd64
VERS=9.1
TARGET=/Volumes/Timemachine/Qemu/NetBSD
SIZE=10G

if [ -n "$1" ]; then
	ARCH=$1
fi

if [ -n "$2" ]; then
	VERS=$2
fi

if [ -n "$3" ]; then
	TARGET=$3
fi

EMU=$ARCH
if [ "$ARCH" = "amd64" ]; then
	EMU="x86_64"
fi

# Make our directory
mkdir -p "$TARGET/$ARCH"
cd "$TARGET/$ARCH"
if [ "$?" != "0" ]; then
	echo "Error creating and changing to the target directory">&2
	exit 1
fi

IMAGE="netbsd-disk-$ARCH.img"
ISO=NetBSD-$VERS-$ARCH.iso
URL="https://cdn.netbsd.org/pub/NetBSD/NetBSD-$VERS/images/$ISO"

if [ -f "$ISO" ]; then
	echo "Using $ISO"
else
	curl --output "$ISO" $URL
fi

if [ -f "$IMAGE" ]; then
	echo "Using existing $IMAGE"
else
	qemu-img create -f raw "$IMAGE" $SIZE
fi
echo "Starting emulator"
qemu-system-$EMU -m 256M -hda $IMAGE -cdrom \
             "$ISO" -display curses -boot d \
             -net nic -net user
