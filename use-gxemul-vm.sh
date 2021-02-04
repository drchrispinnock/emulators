#!/bin/sh

# Setup or run a BSD emulator from scratch
#
# Chris Pinnock Feb/2021 - No Warranty - Use at your own risk!
#
# Usage: $0 [[[[[OS] Arch] version]
# e.g.
# $0 OpenBSD i386

# CDNs
NETBSDCDN="https://cdn.netbsd.org/pub/NetBSD"
OPENBSDCDN="https://cloudflare.cdn.openbsd.org/pub/OpenBSD"
FREEBSDCDN="https://download.freebsd.org/ftp/releases"

# Defaults
DEBUG=1
OS=NetBSD
ARCH=pmax
SIZE=8G
MEMORY=256M
IMGSIZE=7800000
SETUP=0
IKERN=""
KERN=""
X="-X"

if [ "$1" = "-i" ]; then
	SETUP=1
	shift
fi

# Get the OS from the command-line
#
if [ -n "$1" ]; then
	OS=$1
fi

LOWEROS=`echo $OS | awk '{print tolower($0)}'`
TARGET=$HOME/GXemul/$OS

# Determine the architecture
#
if [ -n "$2" ]; then
	ARCH=$2
fi

EMU="-e $ARCH"

IMAGE="$LOWEROS-disk-$ARCH.img"
# Fix depending on OS and arch
case $OS in
	NetBSD)
		VERS=9.1
		case $ARCH in
			pmax)
				;;
			cats)
				# Boots but does not install
				IKERN=netbsd-INSTALL.aout.gz
				KERN=netbsd-GENERIC.aout.gz
				;;
			macppc)
				KERN=netbsd-GENERIC.MP.gz
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
#			sgi)
#				;;
			*)
				echo "$OS/$ARCH not supported">&2
				exit 1
				;;
		esac
		;;
		FreeBSD)
	  	VERS=12.2
			case $ARCH in
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

# Operating system specifics across the architectures
#
case $OS in
	NetBSD)
		ISO=$OS-$VERS-$ARCH.iso

		REMOTEISO=$ISO
		if [ "$ARCH" = "mips64el" ]; then
			REMOTEISO=$OS-$VERS-evbmips-mips64el.iso
		fi
	
		URL="$NETBSDCDN/NetBSD-$VERS/images/$REMOTEISO"
		FURL="$NETBSDCDN/NetBSD-$VERS/$ARCH/binary/kernel"
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
	TARGET="$5/$OS"
fi

if [ "$DEBUG" = "1" ]; then
	echo "Setting up $OS/$ARCH $VERS"
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

	cats)
		EMU="-E cats"
		;;
  	pmax)
	  	EMU="-e 3max"
	;;
	macppc)
		EMU="-e g4"
		#X="-x"
	;;
esac


if [ "$IKERN" != "" ]; then
	if [ ! -f "$IKERN" ]; then
		echo "No install kernel - setting up"
		SETUP=1
	fi
fi

if [ "$KERN" != "" ]; then
	if [ ! -f "$KERN" ]; then
		echo "No runtime kernel - setting up"
		SETUP=1
	fi
fi

if [ ! -f "$IMAGE" ]; then
		echo "No image - setting up"
		SETUP=1
fi

if [ "$SETUP" = 1 ]; then

	if [ -f "$ISO" ]; then
	  echo "Using existing $ISO file">&2
	else
	  echo "Downloading $ISO">&2
	
	echo "curl --location --output \"$ISO\" \"$URL\""
	
	curl --location --output $ISO "$URL"
	
	fi

	if [ "$KERN" != "" ]; then
		if [ -f "$KERN" ]; then
		  echo "Using existing $KERN file">&2
		else
		  echo "Downloading $KERN">&2
	
		echo "curl --location --output \"$KERN\" \"$FURL/$KERN\""
		curl --location --output $KERN "$FURL/$KERN"
		fi
	fi	
	
	if [ "$IKERN" != "" ]; then

		if [ -f "$IKERN" ]; then
		  echo "Using existing $IKERN file">&2
		else
		  echo "Downloading $IKERN">&2
	
		echo "curl --location --output \"$IKERN\" \"$FURL/$IKERN\""
		curl --location --output $IKERN "$FURL/$IKERN"
		fi
	fi
	if [ "$KERN" != "" ] && [ "$IKERN" = "" ]; then
		IKERN=$KERN
	fi

	if [ -f "$IMAGE" ]; then
		echo "Using existing $IMAGE">&2
	else
		echo "Creating $IMAGE">&2
		dd if=/dev/zero of=$IMAGE bs=1024 count=1 seek=$IMGSIZE
	fi
	echo "Starting emulator to boot from install media"
	echo "gxemul $X $EMU -d $IMAGE -d b:$ISO $IKERN"
	sleep 2
	gxemul $X $EMU -d $IMAGE -d b:$ISO $IKERN

else
	echo "Starting emulator to boot:"
	echo "gxemul $X $EMU -d $IMAGE $KERN"
	sleep 2
	gxemul $X $EMU -d $IMAGE $KERN
fi

