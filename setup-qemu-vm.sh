#!/bin/sh

# Setup a BSD emulator from scratch
#
# Chris Pinnock Feb/2021 - No Warranty - Use at your own risk!
#
# Supported architectures
# NetBSD - amd64, i386, sparc, sparc64, macppc
# OpenBSD - amd64, i386, sparc64
# FreeBSD - i386, amd64, sparc64
# Solaris - i386

# Usage: $0 [[[[[OS] Arch] NOGUI] Size] Target Dir]
# e.g.
# $0 OpenBSD i386

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
		VERS=10   # If you want 11, there's a VMware image
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
				echo "Use setup-arm64.sh">&2 # XXX
				exit 1
				;;
			macppc)
				EMU="ppc"
				VERS=9.0	# 9.1 is broken for some reason
				OFWBOOT="-prom-env boot-device=cd:,\\ofwboot.xcf"
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
#			prep)
#				EMU="ppc"
#				MEMORY="192M"
#				OFWBOOT="-prom-env auto-boot?=false"
#			  ;;
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
				echo "machine mac99 gives as far as adb0 and hangs">&2
				echo "machine mac99, via=pmu gets further but panics at ohci0">&2
				echo "machine mac99, via=pmu-adb gets further but hangs at ohci0">&2
				echo "6.8 halts on pmu-adb. I'm sure OpenBSD could be fixed to boot">&2
				echo "machine default boots but panics">&2
				echo "Tried 6.4-6.8 - EXITING">&2
			  exit 1
				;;
				powerpc64)
				EMU=ppc64
				echo "Work in progress">&2
				exit 1
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
		echo "Supported OSes: NetBSD, OpenBSD, FreeBSD">&2
		exit 1
		;;
esac

# Fix version from the command line
if [ -n "$3" ]; then
	VERS=$3
fi

# Tidy ups for version dependencies per OS & architecture
#
case $OS in
	
	OpenBSD)
		case $ARCH in
		
			macppc)
		
				# Machine = mac99 gets further than generic
				# but hangs at adb0. Also mem not config'ed
				# via=pmu - gets further but panics when the USB bus is probed
				# via=pmu-adb get further but hangs when the USB bus is proced
				OFWBOOT="-L pc-bios -machine mac99,via=pmu-adb -prom-env boot-device=cd:,ofwboot -prom-env boot-file=/$VERS/macppc/bsd.rd"
				;;
				
				powerpc64)
				# Work in progress
				#OFWBOOT="-machine powernv9 -prom-env boot-device=cd:,ofwboot -prom-env boot-file=/$VERS/macppc/bsd.rd"
				#OFWBOOT="-prom-env boot-device=cd:,ofwboot -prom-env boot-file=/$VERS/macppc/bsd.rd"
				OFWBOOT=""
				;;
			*)
				echo "$OS/$ARCH not supported">&2
				exit 1
				;;
		esac
		;;
		
  *)
		
		;;
esac

# Operating system specifics across the architectures
#
case $OS in
	Solaris)
	ARCH1=x86
	if [ "$ARCH" = "sparc64" ]; then 
		ARCH1=sparc
	fi
	ISO="sol-$VERS-u11-ga-$ARCH1-dvd.iso"
	URL="" #Not used
	;;
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
	FreeBSD)
		ISO="FreeBSD-$VERS-RELEASE-$ARCH-disc1.iso"
		URL="$FREEBSDCDN/$ARCH/$ARCH/ISO-IMAGES/$VERS/$ISO"

		;;
	Debian)
		MEMORY=512M
		ISO=debian-$VERS-$ARCH-netinst.iso
		URL="$DEBIANCDN/$ARCH/iso-cd/$ISO"
		;;
   *)
	 	echo "Should not be reached!" >&2
		exit 1
esac

# Fix version from the command line
#
if [ -n "$4" ]; then
	SIZE=$4
fi

if [ -n "$5" ]; then
	TARGET="$5/$OS"
fi

if [ "$DEBUG" = "1" ]; then
	echo "Setting up $OS/$ARCH $VERS using qemu $EMU">&2
	echo "Install media location: $URL">&2
	echo "Local name: $ISO">&2
	echo "Using target: $TARGET/$ARCH">&2
	echo "">&2
	sleep 1
fi
# Make our directory
#
mkdir -p "$TARGET/$ARCH"
cd "$TARGET/$ARCH"
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
			echo "### Place them in $TARGET/$ARCH">&2
			exit 1
		fi
		;;
	esac

case $ARCH in
#  arc)
#  QEMUFLAGS="-machine magnum -m $MEMORY -hda $IMAGE -cdrom "$ISO" $CURSES -boot d -net user -net nic"
#  ;;
	i386|amd64)
	QEMUFLAGS="-m $MEMORY -hda $IMAGE -cdrom "$ISO" $CURSES -boot d -net user -net nic"
  ;;
#  mac68k)
#  QEMUFLAGS="$QEMUFLAGS -kernel netbsd-GENERIC.bz2"
# ;;

#  prep)
#	QEMUFLAGS="$OFWBOOT -M 40p -m $MEMORY -hda $IMAGE -fda sysinst.fs -cdrom "$ISO" $CURSES -boot c -net user -net nic -nographic"
#	;;
  macppc|powerpc)
	
	# I need the ISO to boot from after installation
	echo "$ISO" > usemeasroot.txt
	QEMUFLAGS="$OFWBOOT -boot order=d -cdrom $ISO $IMAGE" 
	# My terminal hangs in curses on nographic, I've left it off
  ;;
	
  powerpc64)
	# I need the ISO to boot from after installation
	echo "$ISO" > usemeasroot.txt
	QEMUFLAGS="$OFWBOOT -boot order=d -drive file=$IMAGE,if=scsi,bus=0,unit=0,format=raw,media=disk -drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom" 
	;;
	
	sparc64)
	QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0 -drive file=$ISO,format=raw,if=ide,bus=1,unit=0,media=cdrom,readonly=on -boot d -net user -net nic"
	
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
	
	echo "curl --location --output \"$ISO\" \"$URL\""
	
	curl --location --output $ISO "$URL"
	
fi

if [ -f "$IMAGE" ]; then
	echo "Using existing $IMAGE">&2
else
	echo "Creating $IMAGE">&2
	qemu-img create -f raw "$IMAGE" $SIZE
fi

echo "Starting emulator to boot from install media"
echo "qemu-system-$EMU $EXTRAFLAGS $QEMUFLAGS"
sleep 2
qemu-system-$EMU $EXTRAFLAGS $QEMUFLAGS

# FreeBSD also has VM images
#VM=FreeBSD-$VERS-$ARCH.qcow2
#VMURL="$BASEURL/VM-IMAGES/$VERS/$ARCH/Latest/$VM.xz"
