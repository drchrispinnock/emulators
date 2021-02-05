#!/bin/sh

# Setup or run a BSD emulator from scratch
#
# Chris Pinnock Feb/2021 - No Warranty - Use at your own risk!
#
# Supported architectures
# NetBSD - amd64, i386, sparc, sparc64, macppc
# OpenBSD - amd64, i386, sparc64
# FreeBSD - i386, amd64, sparc64
# Debian - amd64
# Solaris - i386

# Usage: $0 [[[[[OS] Arch] NOGUI] Size] Target Dir]
# e.g.
# $0 [-i] OpenBSD i386 - run the installer
# $0 OpenBSD i386 - run the VM or the installer if it isn't setup

# CDNs
NETBSDCDN="https://cdn.netbsd.org/pub/NetBSD"
OPENBSDCDN="https://cloudflare.cdn.openbsd.org/pub/OpenBSD"
FREEBSDCDN="https://download.freebsd.org/ftp/releases"
DEBIANCDN="https://cdimage.debian.org/debian-cd/current/"
SOLARISCDN="" # Needs a login, can't download automagically

# Defaults
DEBUG=1
OS=NetBSD
ARCH=amd64
SIZE=8G
MEMORY=256M
EXTRAFLAGS=""
SETUP=""

NEEDISO="" # Need ISO for regular operation

if [ "$1" = "-i" ]; then
	# Setup
	SETUP=1
	shift
fi

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

# brew version seems to support curses. Perhaps need to recompile
# -nographic doesn't work with NetBSD 
#CURSES="-display curses"
CURSES=""

IMAGE="$LOWEROS-disk-$ARCH.img"
# Fix depending on OS and arch
case $OS in
  Solaris|Slowaris)
	  OS=Solaris # Sorry everyone. I did enjoy using it for work years ago :-)
		VERS=10   
		MEMORY=1G 		# Memory hungry
		case $ARCH in
			i386)
			;;
			*)
			echo "$OS/$ARCH not supported">&2
			exit 1
			;;
		esac
  ;;
	NetBSD)
		VERS=9.1
		case $ARCH in
			i386)
				# Supported for NetBSD
				;;
				sparc64|sparc)
				EXTRAFLAGS="-nographic" 
				;;
			amd64)
				EMU="x86_64"
				;;
			arm64)
			if [ "$SETUP" = "1" ]; then
				echo "Use setup-arm64.sh">&2 # XXX we should really setup here
				exit 1
			fi
				;;
			macppc)
				EMU="ppc"
				VERS=9.0	# 9.1 is broken for some reason
				OFWBOOT="-prom-env boot-device=cd:,\\ofwboot.xcf"
				echo "### Warning: 9.1 does not work (uses 9.0 by default)">&2
				NEEDISO=1
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
			*)
				echo "$OS/$ARCH not supported">&2
				exit 1
				;;
		esac
		;;
		FreeBSD)
	  	VERS=12.2
			case $ARCH in
			i386|sparc64)
					# Supported for FreeBSD
					;;
				amd64)
					EMU="x86_64"
					;;
				*)
					echo "$OS/$ARCH not supported">&2
					exit 1
					;;
			esac
			;;
		Debian)
		VERS=10.7.0
			case $ARCH in
				amd64)
					# Debian
					EMU="x86_64"
					;;
				*)
					echo "$OS/$ARCH not supported">&2
					exit 1
					;;
			esac
			;;
		
  *)
		echo "Supported OSes: NetBSD, OpenBSD, FreeBSD, Debian, Solaris">&2
		exit 1
		;;
esac

# Fix version from the command line
if [ -n "$3" ]; then
	VERS=$3
fi

# Operating system specifics across the architectures
#
case $OS in
	Solaris)
	ARCH1=x86
	if [ "$ARCH" = "sparc64" ]; then 
		ARCH1=sparc # This isn't used but is here for completeness
	fi
	ISO="sol-$VERS-u11-ga-$ARCH1-dvd.iso"
	URL="" #Not used for Solaris
	;;
	NetBSD)
		ISO=$OS-$VERS-$ARCH.iso
		URL="$NETBSDCDN/NetBSD-$VERS/images/$ISO"
		;;
	OpenBSD)
		DOTLESS=`echo $VERS | sed -e 's/\.//g'`
		ISO="install$DOTLESS.iso"
		URL="$OPENBSDCDN/$VERS/$ARCH/$ISO"
		;;
	FreeBSD)
		ISO="FreeBSD-$VERS-RELEASE-$ARCH-disc1.iso"
		URL="$FREEBSDCDN/$ARCH/$ARCH/ISO-IMAGES/$VERS/$ISO"
		;;
	Debian)
		MEMORY=512M # Installer complains of low memory
		ISO=debian-$VERS-$ARCH-netinst.iso
		URL="$DEBIANCDN/$ARCH/iso-cd/$ISO"
		;;
   *)
	 	echo "Should not be reached - $OS/$ARCH/$VERS" >&2
		exit 1
esac

# Fix version from the command line
#
if [ -n "$4" ]; then
	SIZE=$4
fi

FINALTARGET="$TARGET/$ARCH/$VERS"
if [ "$DEBUG" = "1" ]; then
	echo "$OS/$ARCH $VERS using qemu $EMU">&2
	[ "$SETUP" = "1" ] && echo "Setup requested on CLI">&2
	echo "Install media location: $URL">&2
	echo "Local installation name: $ISO">&2
	echo "Using target: $FINALTARGET">&2
	echo "">&2
	sleep 1
fi
# Make our directory
#
mkdir -p "$FINALTARGET"
cd "$FINALTARGET"
if [ "$?" != "0" ]; then
	echo "### Error creating and changing to the target directory">&2
	exit 1
fi

# OS dependencies on ISO download - Solaris at the mo
#
case $OS in
	Solaris)
		if [ ! -f "$ISO" ]; then
			echo "### Please download the ISOs from Oracle">&2
			echo "### You will need a login">&2
			echo "### Place them in $FINALTARGET">&2
			exit 1
		fi
		;;
	esac

if [ -f "$ISO" ]; then
  echo "Installation $ISO file present">&2
else
	
	if [ "$SETUP" = "1" ] || [ "$NEEDISO" = 1 ]; then
	
  	echo "Downloading $ISO">&2	
		echo "curl --location --output \"$ISO\" \"$URL\""
	
		curl --location --output $ISO "$URL"
	fi
fi

if [ -f "$IMAGE" ]; then
	echo "Using existing hard disc $IMAGE">&2
else
	echo "Creating $IMAGE">&2
	qemu-img create -f raw "$IMAGE" $SIZE
	[ "$SETUP" != "1" ] && echo "Changing to Setup mode">&2
	SETUP=1
fi
BOOT="c"
if [ "$SETUP" = "1" ] ; then
	BOOT="d"
fi
INSTALLFLAGS=""


case $ARCH in
	i386|amd64)
	QEMUFLAGS="-m $MEMORY -hda $IMAGE $CURSES -net user -net nic"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-cdrom $ISO"
  ;;
  macppc|powerpc)
	# I need the ISO to boot from after installation
	#
	QEMUFLAGS="$OFWBOOT $IMAGE" 
	INSTALLFLAGS="-cdrom $ISO" # CD is needed for regular running...
  ;;
	sparc64)
	QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0 -net user -net nic"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-drive file=$ISO,format=raw,if=ide,bus=1,unit=0,media=cdrom,readonly=on"
	;;
	sparc)
	QEMUFLAGS="-drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk -net user -net nic"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom,readonly=on"
  ;;
	*)
		echo "QEMUFlags case - $OS/$ARCH - I should not have been reached!">&2
		exit 1
	;;
esac

echo "Starting emulator"
echo "qemu-system-$EMU $EXTRAFLAGS $QEMUFLAGS $INSTALLFLAGS"
sleep 2
qemu-system-$EMU $EXTRAFLAGS $QEMUFLAGS $INSTALLFLAGS -boot $BOOT
