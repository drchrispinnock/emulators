#!/bin/sh

# Setup a BSD emulator from scratch
#

# Usage: $0 [[[[[OS] Arch] NOGUI] Size] Target Dir]
# e.g.
# $0 OpenBSD i386

# CDNs
NETBSDCDN="https://cdn.netbsd.org/pub/NetBSD"
OPENBSDCDN="https://cloudflare.cdn.openbsd.org/pub/OpenBSD"

# Defaults
DEBUG=1
OS=NetBSD
ARCH=amd64
SIZE=10G

# Get the OS from the command-line
#
if [ -n "$1" ]; then
	OS=$1
fi

LOWEROS=`echo $OS | awk '{print tolower($0)}'`
TARGET=$HOME/Qemu/$OS

# Determine the architecture
#
if [ -n "$2" ]; then
	ARCH=$2
fi

EMU=$ARCH
CURSES="-display curses" # -nographic?

IMAGE="$LOWEROS-disk-$ARCH.img"
# Fix depending on OS and arch
case $OS in
	NetBSD)
		VERS=9.1
		case $ARCH in
			i386|sparc64|sparc)
				# Supported for NetBSD
				;;
			amd64)
				EMU="x86_64"
				;;
			arm64)
				echo "Use setup-arm64.sh">&2 # XXX
				exit 1
				;;
			macppc)
				EMU="ppc"
				VERS=9.0	# 9.1 is broken for some reason
				echo "Warning: macppc needs attention at boot time after install">&2
				echo "Warning: 9.1 does not work (uses 9.0 by default)">&2
				;;
			mac68k)
				EMU="m68k"
				echo "Warning: Does not work currently">&2
				;;
			mips64el)
				echo "Warning: Does not work currently">&2
				CURSES="-nographic"
				;;
			*)
				echo "$OS/$ARCH not supported">&2
				exit 1
				;;
		esac
		
  	;;
	OpenBSD)
  	VERS=6.8
		case $ARCH in
			i386|sparc64)
				# Supported for OpenBSD
				;;
			amd64)
				EMU="x86_64"
				;;
			macppc)
				EMU="ppc"
			
				echo "Warning: macppc needs attention at boot time after install">&2
				echo "Warning: testing!!! ">&2
				;;
			*)
				echo "$OS/$ARCH not supported">&2
				exit 1
				;;
		esac
		;;
  *)
		echo "$OS not supported (yet)">&2
		exit 1
		;;
esac

# Fix version from the command line
if [ -n "$3" ]; then
	VERS=$3
fi

case $OS in
	NetBSD)
		ISO=$OS-$VERS-$ARCH.iso
		REMOTEISO=$ISO
		if [ "$ARCH" = "mips64el" ]; then
			REMOTEISO=$OS-$VERS-evbmips-mips64el.iso
		fi
		
		URL="$NETBSDCDN/NetBSD-$VERS/images/$REMOTEISO"
		;;
	OpenBSD)
		DOTLESS=`echo $VERS | sed -e 's/\.//g'`
		ISO="install$DOTLESS.iso"
		
		URL="$OPENBSDCDN/$VERS/$ARCH/$ISO"
		;;
   *)
	 	echo "Should not be reached!" > 2&1
		exit 1
esac

# Fix version from the command line
#
if [ -n "$4" ]; then
	SIZE=$4
fi

if [ -n "$5" ]; then
	TARGET=$5/$OS
fi

if [ "$DEBUG" = "1" ]; then
	echo "Setting up $OS/$ARCH $VERS using qemu $EMU"
	echo "Install media location: $URL"
	echo "Local name: $ISO"
	echo "Using target: $TARGET/$ARCH"
fi
# Make our directory
#
mkdir -p "$TARGET/$ARCH"
cd "$TARGET/$ARCH"
if [ "$?" != "0" ]; then
	echo "Error creating and changing to the target directory">&2
	exit 1
fi

case $ARCH in
	i386|amd64)
	QEMUFLAGS="-m 256M -hda $IMAGE -cdrom "$ISO" $CURSES -boot d -net user -net nic"
  ;;
#  mac68k)
#  QEMUFLAGS="$QEMUFLAGS -kernel netbsd-GENERIC.bz2"
# ;;

  macppc)
	# I need the ISO to boot from after installation
	echo "$ISO" > usemeasroot.txt
	QEMUFLAGS="-prom-env "boot-device=cd:,\\ofwboot.xcf" -boot order=d -cdrom $ISO $IMAGE" 
	# My terminal hangs in curses on nographic, I've left it off
  ;;

	sparc64)
	QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0 -drive file=$ISO,format=raw,if=ide,bus=1,unit=0,media=cdrom,readonly=on -boot d -net user -net nic -nographic" 
	# Use nographic for the installer
	;;
	sparc)
	QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom,readonly=on -boot d -net user -net nic -nographic"
  ;;
	*)
		echo "QEMUFlags case - $ARCH - I should not have been reached!">&2
		exit 1
	;;
esac

if [ -f "$ISO" ]; then
	echo "Using existing $ISO file">&2
else
	echo "Downloading $ISO">&2
	curl -L --output "$ISO" $URL
fi

if [ -f "$IMAGE" ]; then
	echo "Using existing $IMAGE">&2
else
	echo "Creating $IMAGE">&2
	qemu-img create -f raw "$IMAGE" $SIZE
fi

echo "Starting emulator to boot from install media"
echo "qemu-system-$EMU $QEMUFLAGS"
sleep 2
qemu-system-$EMU $QEMUFLAGS

