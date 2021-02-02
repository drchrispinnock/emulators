#!/bin/sh

# Setup a NetBSD emulator from scratch

OS=NetBSD
LOWEROS=`echo $OS | awk '{print tolower($0)}`

ARCH=amd64
VERS=9.1
TARGET=$HOME/Qemu/$OS
SIZE=10G

if [ -n "$1" ]; then
	ARCH=$1
fi

EMU=$ARCH
CURSES="-display curses"

case $ARCH in
	i386|sparc|sparc64|amd64)
		# Supported
		;;
	amd64)
		EMU="x86_64"
		;;
	arm64)
		echo "Use setup-arm64.sh">&2
		exit 1
		;;
	macppc)
		EMU="ppc"
		VERS=9.0	# 9.1 is broken for some reason
		echo "Warning: macppc needs attention at boot time after install">&2
		echo "Warning: 9.1 does not work (uses 9.0 by default) ">&2
		;;
	mac68k)
		echo "Warning: Does not work currently">&2
		;;
	mips64el)
		echo "Warning: Does not work currently">&2
		CURSES="-nographic"
		;;
	*)
		echo "Warning: No idea if this architecture works!">&2
		;;
esac

if [ -n "$2" ]; then
	VERS=$2
fi

IMAGE="$LOWEROS-disk-$ARCH.img"
ISO=$OS-$VERS-$ARCH.iso
REMOTEISO=$ISO

if [ "$ARCH" = "mips64el" ]; then
	REMOTEISO=$OS-$VERS-evbmips-mips64el.iso
fi



if [ -n "$3" ]; then
	TARGET=$3
fi

# Mismatch with QEMU emulators


if [ "$ARCH" = "mac68k" ]; then
	EMU="m68k"
	echo "mac68k is not supported">&2
	exit 1
fi

# Make our directory
mkdir -p "$TARGET/$ARCH"
cd "$TARGET/$ARCH"
if [ "$?" != "0" ]; then
	echo "Error creating and changing to the target directory">&2
	exit 1
fi


URL="https://cdn.netbsd.org/pub/NetBSD/NetBSD-$VERS/images/$REMOTEISO"

# i386, amd64
QEMUFLAGS="-m 256M -hda $IMAGE -cdrom "$ISO" $CURSES -boot d -net user $EXTRAFLAGS -net nic"

# mac68k needs a kernel
#QEMUFLAGS="$QEMUFLAGS -kernel netbsd-GENERIC.bz2"

if [ "$ARCH" = "macppc" ]; then
	echo "$ISO" > usemeasroot.txt
	QEMUFLAGS="-prom-env "boot-device=cd:,\\ofwboot.xcf" -boot order=d -cdrom $ISO $IMAGE" # My terminal hangs in curses on nographic
fi

# sparc64
if [ "$ARCH" = "sparc64" ]; then
	QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0 -drive file=$ISO,format=raw,if=ide,bus=1,unit=0,media=cdrom,readonly=on -boot d -net user -net nic -nographic"
fi

# sparc
if [ "$ARCH" = "sparc" ]; then
	QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom,readonly=on -boot d -net user -net nic -nographic"
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
