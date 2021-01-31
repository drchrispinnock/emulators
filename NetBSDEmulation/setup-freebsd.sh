#!/bin/sh

# Setup a FreeBSD emulator from scratch
#
ARCH=amd64
REL=12.2
VERS=$REL-RELEASE
TARGET=$HOME/Qemu/FreeBSD
SIZE=10G
VMIMAGE=0 # Several architectures provide a VM image.

if [ -n "$1" ]; then
	ARCH=$1
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
	VMIMAGE=1
fi

if [ "$ARCH" = "i386" ]; then
	VMIMAGE=1
fi

if [ "$ARCH" = "aarch64" ]; then
	VMIMAGE=1
fi

if [ "$ARCH" = "macppc" ]; then
	EMU="ppc"
fi

# Make our directory
mkdir -p "$TARGET/$ARCH"
cd "$TARGET/$ARCH"
if [ "$?" != "0" ]; then
	echo "Error creating and changing to the target directory">&2
	exit 1
fi

IMAGE="freebsd-disk-$ARCH.img"
ISO=FreeBSD-$VERS-$ARCH-disc1.iso
VM=FreeBSD-$VERS-$ARCH.qcow2

BASEURL="https://download.freebsd.org/ftp/releases
ISOURL="$BASEURL/$ARCH/$ARCH/ISO-IMAGES/$REL.xz"
VMURL="$BASEURL/VM-IMAGES/$VERS/$ARCH/Latest/$VM.xz"

# i386, amd64
QEMUFLAGS="-m 256M -hda $IMAGE -cdrom "$ISO" -display curses -boot d -net user $EXTRAFLAGS -net nic"

if [ -f "$VM

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
