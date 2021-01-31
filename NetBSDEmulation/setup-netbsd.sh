#!/bin/sh

# Setup a NetBSD emulator from scratch

ARCH=amd64
VERS=9.1
TARGET=$HOME/Qemu/NetBSD
SIZE=10G
CURSES="-display curses"

if [ -n "$1" ]; then
	ARCH=$1
fi

if [ "$ARCH" = "sparc" ]; then
#	VERS="7.2" # 9.1 doesn't work

	echo "do nothing"
fi

if [ "$ARCH" = "sparc64" ]; then
	VERS="7.0" # 9.1 doesn't work
fi


if [ -n "$2" ]; then
	VERS=$2
fi

if [ -n "$3" ]; then
	TARGET=$3
fi

# Mismatch with QEMU emulators
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

# i386, amd64
QEMUFLAGS="-m 256M -hda $IMAGE -cdrom "$ISO" $CURSES -boot d -net user $EXTRAFLAGS -net nic"

# sparc64 - under test
if [ "$ARCH" = "sparc64" ]; then
	CURSES=""
	QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom,readonly=on -device virtio-blk-pci,bus=pciB,drive=hd -boot d -nographic"
fi

# space
if [ "$ARCH" = "sparc" ]; then
	CURSES=""
	QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom,readonly=on -boot d -nographic"
fi

if [ -f "$ISO" ]; then
	echo "Using $ISO"
else
	curl -L --output "$ISO" $URL
fi

if [ -f "$IMAGE" ]; then
	echo "Using existing $IMAGE"
else
	qemu-img create -f raw "$IMAGE" $SIZE
fi
echo "Starting emulator"
echo "qemu-system-$EMU $QEMUFLAGS"
sleep 2
qemu-system-$EMU $QEMUFLAGS
