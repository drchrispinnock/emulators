#!/bin/sh

# Run NetBSD emulator 

ARCH=amd64
CURSES="-display curses"
TARGET=$HOME/Qemu/NetBSD

if [ -n "$1" ]; then
	ARCH=$1
fi

if [ "$ARCH" = "sparc64" ]; then
	CURSES="-nographic"
fi

if [ "$ARCH" = "sparc" ]; then
	CURSES="-nographic"
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

# i386/amd64/default
QEMUFLAGS="-m 256M -hda $IMAGE -cdrom $ISO -boot d -net user -net nic"

# Sparc/sun4m
if [ "$ARCH" = "sparc" ]; then
	QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -net user -net nic"
fi

# Sparc64/sun4u
if [ "$ARCH" = "sparc64" ]; then
	QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0 -net user -net nic"
fi

if [ -f "$IMAGE" ]; then

	echo "Starting emulator"

	if [ -n "$CURSES" ]; then
		echo -n -e "\033]0;QEMU-NetBSD/$ARCH\007"
	fi

	echo "qemu-system-$EMU $QEMUFLAGS $CURSES"
	qemu-system-$EMU $QEMUFLAGS $CURSES
else
	echo "No $IMAGE!"
fi
