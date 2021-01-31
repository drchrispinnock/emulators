#!/bin/sh

# Run NetBSD emulator 

ARCH=amd64
CURSES="-display curses"
TARGET=$HOME/Qemu/NetBSD

if [ -n "$1" ]; then
	ARCH=$1
fi

if [ -n "$2" ]; then
	CURSES=""
fi

if [ -n "$3" ]; then
	TARGET=$3
fi

EMU=$ARCH
if [ "$ARCH" = "amd64" ]; then
	EMU="x86_64"
fi

if [ ! -d "$TARGET/$ARCH" ]; then
	echo "Emulator not installed where I expect!">&2
	exit 1
fi

cd "$TARGET/$ARCH"
if [ "$?" != "0" ]; then
	echo "Error creating and changing to the target directory">&2
	exit 1
fi

IMAGE="netbsd-disk-$ARCH.img"

if [ -f "$IMAGE" ]; then
echo "Starting emulator"
	qemu-system-$EMU -m 256M -hda $IMAGE -boot d -net nic -net user \
		-display curses
else
	echo "No $IMAGE!"
fi
