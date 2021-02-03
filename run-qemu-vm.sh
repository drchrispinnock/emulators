#!/bin/sh

# Run emulator 

OS=NetBSD
ARCH=amd64
CURSES="" # -nographic doesn't like NetBSD; brew version allows display curses
ALTCURSES=""

if [ -n "$1" ]; then
	OS=$1
fi
LOWER=`echo $OS | awk '{print tolower($0)}'`
TARGET=$HOME/Qemu/$OS
echo $TARGET

if [ -n "$2" ]; then
	ARCH=$2
fi

IMAGE="$LOWER-disk-$ARCH.img"
EMU=$ARCH
case $ARCH in
	sparc64)
		CURSES="-nographic"
		QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0 -net user -net nic"
	;;
	sparc)
		CURSES="-nographic"
		QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -net user -net nic"
	;;
	
	amd64)
		EMU="x86_64"
		QEMUFLAGS="-m 256M -hda $IMAGE -net user -net nic"
		;;
		i386)
		QEMUFLAGS="-m 256M -hda $IMAGE -net user -net nic"
		;;
	arm64)
		 CURSES="-nographic"
		ALTCURSES="-device ramfb -device nec-usb-xhci,id=xhci -device usb-mouse,bus=xhci.0 -device usb-kbd,bus=xhci.0"
		EMU=aarch64
		;;
	*)
		;;
esac
						
if [ -n "$3" ]; then
	CURSES=$ALTCURSES
fi

if [ -n "$4" ]; then
	TARGET=$4
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

case $OS in
	NetBSD)
		case $ARCH in
			macppc)
				EMU="ppc"
				ISO=`cat usemeasroot.txt`

# Annoyingly -a does not get passed to the bootloader
#				QEMUFLAGS="-prom-env boot-device=cd:,\\ofwboot.xcf\ -prom-env boot-file=netbsd.macppc -prom-env boot-args=-a -boot d -cdrom $ISO -hda $IMAGE" # - we need a CD image with the kernel & booted on it for this
# We do this to drop to Boot: which understands "netbsd.macppc -a"
			QEMUFLAGS="-boot d -prom-env boot-device=cd:,\\ofwboot.xcf -prom-env boot-file=notfound -cdrom $ISO -net user -net nic $IMAGE"
				;;
			arm64)
			 QEMUFLAGS="-M virt -cpu cortex-a53 -smp 4 -m 4g -drive if=none,file=$IMAGE,id=hd0 -device virtio-blk-device,drive=hd0 -netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 -bios QEMU_EFI.fd"
						;;
						*)
						;;
					esac
				esac

if [ -f "$IMAGE" ]; then

	echo "Starting emulator"

	if [ -n "$CURSES" ]; then
		echo -n -e "\033]0;QEMU-$OS/$ARCH\007"
	fi

	echo "qemu-system-$EMU $QEMUFLAGS $CURSES"
	qemu-system-$EMU $QEMUFLAGS $CURSES
else
	echo "No $IMAGE!"
fi
