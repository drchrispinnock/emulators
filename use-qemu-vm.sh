#!/bin/sh

# Setup or run a BSD emulator from scratch
#
# Chris Pinnock Feb/2021 - No Warranty - Use at your own risk!
#
# Supported architectures
# NetBSD - amd64, i386, sparc, sparc64, macppc, hppa
# OpenBSD - amd64, i386, sparc64
# FreeBSD - i386, amd64, sparc64
# Debian - amd64
# Solaris 10 - i386
# Solaris 2.6, 7, 8, 9 - sparc
# Plan9 - amd64
# Minix - amd64
# Dragonfly - amd64 (installer halts at 17%)

# Usage: $0 [[[[[OS] Arch] NOGUI] Size]
# e.g.
# $0 [-i] OpenBSD i386 - run the installer
# $0 OpenBSD i386 - run the VM or the installer if it isn't setup
USAGE="$0 [-6] [-X] [-F] [-i] [-c] [-n] [-d] [-P port] [-R FreeBSDRel] 
    [-t TargetDir] [-m memory] [-s hd size] [OS [arch [ver]]]

  -i run installer ISO
  -c use -display curses
  -n use -nographic (overrides -c)
  -d more output
  -P sets local SSH port
  -t specifies an alternative target directory for files
  -X clean up the ISO file and start again
  -F just fetch the ISO
  -6 specify ipv6=no (some VMs have trouble connecting)

  OS can be NetBSD, OpenBSD, FreeBSD, DragonFly, Minix, Plan9,
  Debian or Solaris."

# Set the environment variable QEMUTARGET if you want an
# alternative to $HOME/VM/Qemu

# CDNs
NETBSDCDN="https://cdn.netbsd.org/pub/NetBSD"
NETBSDARCHIVE="http://archive.netbsd.org/pub/NetBSD-archive"

OPENBSDCDN="https://cloudflare.cdn.openbsd.org/pub/OpenBSD"
FREEBSDCDN="https://download.freebsd.org/ftp/releases"
DEBIANCDN="https://cdimage.debian.org/debian-cd/current/"
SOLARISCDN="" # Needs a login, can't download automagically
PLAN9CDN="https://plan9.io/plan9/download"
MINIXCDN="http://download.minix3.org/iso/"
DFCDN="http://mirror-master.dragonflybsd.org/iso-images/"

# Defaults
DEBUG=0
OS=NetBSD
ARCH=amd64
SIZE=8G
EXTRAFLAGS=""
SETUP="0"
IMGFORMAT="qcow2"

FREEBSDREL="RELEASE"

NEEDISO="" 	# Need ISO for regular operation
ZAPISO="" 	# start again with the ISO
ONLYGETISO="" 	# start again with the ISO
NOIPV6=""	# Some VMs have trouble connecting

CLISIZE=""
CLIMEM=""

# brew version seems to support curses. Perhaps need to recompile
# -nographic doesn't work with NetBSD 
#CURSES="-display curses"
CURSES=""

SSHPORT=""

# CLI options
#
while [ $# -gt 0 ]; do
	case $1 in
  -d|--debug)  DEBUG=1; ;;
	-i|--install|--setup)				
			SETUP="1"; ;;		# Run the installer
	-c|--curses)
			CURSES="-display curses"; ;;
	-n|--nographic)				
			CURSES="-nographic"; ;;
	-t)			  QEMUTARGET="$2"; shift; ;;
	-X)			  ZAPISO="1"; ;;
	-6)			  NOIPV6="1"; ;;
	-F)			  ONLYGETISO="1"; NEEDISO="1" ;;
	-m)			  CLIMEM="$2"; shift; ;;
	-P)			  SSHPORT="$2"; shift; ;;
	-R)			  FREEBSDREL="$2"; shift;  ;;
	-s)       CLISIZE="$2"; shift; ;;
	-h|--help)		
				echo "$USAGE"; exit ;;
	-*)		echo "${0##*/}: unknown option \"$1\"" 1>&2
			  echo "$USAGE" 1>&2; exit 1 ;;
	 *)
		    break; # Exit the while loop, rest of vars dealt with below
	esac 
	shift
done

if [ -n "$1" ]; then
	OS=$1
fi

LOWEROS=`echo $OS | awk '{print tolower($0)}'`

# Environment var
#
if [ "$QEMUTARGET" = "" ]; then
	QEMUTARGET=$HOME/VM/Qemu
fi
TARGET=$QEMUTARGET/$OS

# Determine the architecture
#
if [ -n "$2" ]; then
	ARCH=$2
fi

EMU=$ARCH
IMAGE="$LOWEROS-disk-$ARCH.img"

# Use the correct emulator and machine for the architecture
# i.e. map the OS project names to the Qemu names
#
case $ARCH in
		amd64)
			EMU="x86_64"
			;;
		macppc|powerpc)
			EMU="ppc"
			;;
		prep)
			EMU="ppc"
			EXTRAFLAGS="-M 40p"
			OFWBOOT="-prom-env auto-boot?=false" # XXX
			;;
		evbppc)
			EMU="ppc"
			EXTRAFLAGS="-M ref405ep"
			# Needs ROM
			;;
		evbarm)
			EMU="arm"
			EXTRAFLAGS="-M integratorcp"
			;;
esac


# OPERATING SYSTEMS
# Fix depending on OS and arch
#
KNOWN=0
case $OS in
	Plan9)
	  VERS=latest
		SIZE=4G
		case $ARCH in
			amd64)
			KNOWN=1
			;;
		esac
	;;
	Minix)
		VERS=3.3.0
		case $ARCH in
			amd64)
			KNOWN=1
			;;
		esac
	;;
	Solaris)
		case $ARCH in
			i386)
			KNOWN=1
			MEMORY=1G 		# Memory hungry
			VERS=10
			;;
			amd64)
			KNOWN=1
			MEMORY=4G # Watch it struggle and dump on 1G...
			EXTRAFLAGS="-M q35"
			VERS=11 # Still has trouble on discs
			;;
			sparc)
			KNOWN=1
			VERS=9 # 10/sparc doesn't work on Qemu
			EXTRAFLAGS="-M SS-20"
			CURSES="-nographic"
			#OFWBOOT="-prom-env auto-boot?=false"
			;;
		esac
  ;;
  	Dragonfly|DragonFly|DragonFlyBSD|DragonflyBSD)
		VERS=5.8.3
		OS=DragonFly
		case $ARCH in
			amd64)
			KNOWN=1
			;;
		esac
	;;
	NetBSD)
		VERS=9.1
		case $ARCH in
			i386|sparc64|sparc|amd64|hppa)
				KNOWN=1
				# Supported - no tuning needed
				
				;;
			evbarm)
				KNOWN=1
				echo "### WIP, if it will work"
				exit 1
				;;
			prep)
				KNOWN=2
				echo "### Previously booted WIP"
				sleep 2 
				;;
			evbppc)
				KNOWN=1
				echo "### May work with Walnut rom"
				exit 1;
				;;
			alpha)
				KNOWN=2
				;;
			macppc)
				KNOWN=1
				VERS=9.0	# 9.1 doesn't boot
				
				echo "### Warning: 9.1 does not work (uses 9.0 by default)">&2
				NEEDISO=1
				OFWBOOT="-prom-env boot-device=cd:,\\ofwboot.xcf -prom-env boot-file=notfound" # Regular boot - for setup see later
				;;
		esac
		
  	;;
	OpenBSD)
  	VERS=6.9
		case $ARCH in
			i386|sparc64|amd64)
				# Supported for OpenBSD
				KNOWN=1
				;;
			alpha)
				# Try
				VERS=6.8
				KNOWN=1
				;;
			hppa)
				KNOWN=1
				echo "# XXXX"
				echo "# XXXX Warning - OpenBSD/hppa installs but does not seem to boot normally"
				echo "# XXXX"
				;;
		esac
		;;
		FreeBSD)
	  	VERS=12.2
			case $ARCH in
			i386|amd64)
				KNOWN=1
					
					# Supported for FreeBSD
					;;
				sparc64)
				  # Has trouble without this
					echo "Using -nographic for FreeBSD">&2
					CURSES="-nographic";
					KNOWN=1
					;;
			esac
			;;
		Debian)
		VERS=10.8.0
		
			case $ARCH in
				amd64)
					# Debian
					KNOWN=1
					MEMORY=1G 		# Installer grumbles about memory
					;;
			esac
			;;
		
  *)
		echo "$USAGE">&2
		exit 1
		;;
esac
			
if [ "$KNOWN" = "0" ]; then
	echo "$OS/$ARCH not supported">&2
	exit 1
fi
if [ "$KNOWN" = "2" ]; then
	echo "$OS/$ARCH might not boot or function correctly">&2
fi

# Fix version from the command line
if [ -n "$3" ]; then
	VERS=$3
fi

# Operating system specifics across the architectures
#
case $OS in
	Plan9)
	ISO=plan9.iso
	URL="$PLAN9CDN/$ISO.bz2"
	BUNZIPISO="1"
	;;
	Minix)
	ISO=minix_R3.3.0-588a35b.iso
	URL="$MINIXCDN/$ISO.bz2"
	BUNZIPISO="1"
	;;
	
	Solaris)
	
	# 10/x86 works and is our default
	# 10/sparc/64 doesn't
	ARCH1=x86
	if [ "$ARCH" = "sparc64" ]; then 
		ARCH1=sparc # This isn't used but is here for completeness
	fi
	# 7,8,9 let the user do the work unfortunately
	ISO="Solaris$VERS-$ARCH.iso" 
	[ "$VERS" = "2.6" ] && MEMORY=256M
	[ "$VERS" = "10" ] && ISO="sol-$VERS-u11-ga-$ARCH1-dvd.iso"
	# 11 won't boot properly but it won't boot on virtual box either
	[ "$VERS" = "11" ] && ISO="sol-11_4-text-$ARCH1.iso"
	URL="" #Not used for Solaris
	;;
	NetBSD)
		ISO=$OS-$VERS-$ARCH.iso
		URL="$NETBSDCDN/NetBSD-$VERS/images/$ISO"
		
		A=`echo $VERS | awk -F. '{print $1}'`

		if [ "$A" = "7" ]; then
			URL="$NETBSDCDN/NetBSD-$VERS/$ARCH/installation/cdrom/boot.iso"
		fi
    		if [ "$A" -lt 7 ]; then 
			# Use the archives
			NETBSDCDN="$NETBSDARCHIVE"
		fi
		
		;;
	OpenBSD)
		DOTLESS=`echo $VERS | sed -e 's/\.//g'`
		ISO="install$DOTLESS.iso"
		URL="$OPENBSDCDN/$VERS/$ARCH/$ISO"
		;;
	FreeBSD)
		ISO="FreeBSD-$VERS-$FREEBSDREL-$ARCH-disc1.iso"
		URL="$FREEBSDCDN/$ARCH/$ARCH/ISO-IMAGES/$VERS/$ISO"
		;;
	DragonFly)
		ISO="dfly-x86_64-${VERS}_REL.iso"
		URL="$DFCDN/$ISO.bz2"
		BUNZIPISO="1"
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

[ "$CLISIZE" != "" ] && SIZE=$CLISIZE

[ "$CLIMEM" != "" ] && MEMORY=$CLIMEM
[ "$MEMORY" != "" ] && MEMORY="-m $MEMORY"

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


	if [ -f "$IMAGE" ]; then
		echo "Using existing hard disc $IMAGE">&2
	else
		echo "Creating $IMAGE of size $SIZE">&2
		qemu-img create -f $IMGFORMAT "$IMAGE" $SIZE
		echo "(Using Setup mode)">&2
		SETUP="1"
	fi
	BOOT="-boot c"
	if [ "$SETUP" = "1" ] ; then
		BOOT="-boot d"
	fi

if [ "$ZAPISO" = "1" ]; then
	echo "Removing ISO as requested">&2
	rm -f "$ISO"
fi

if [ -f "$ISO" ]; then
  echo "Installation $ISO file present">&2
else
	
	if [ "$SETUP" = "1" ] || [ "$NEEDISO" = 1 ]; then
		# OS dependencies on ISO download - Solaris at the mo
		if [ "$OS" = "Solaris" ]; then
			echo "### Please download the ISO: $ISO from Oracle">&2
			echo "### You will need a login">&2
			echo "### Older versions may be at archive.org">&2
			echo "### Place them in $FINALTARGET">&2
			exit 1
		fi
	
	  INTERMEDIATE="$ISO"
		if [ "$BUNZIPISO" = "1" ]; then
			INTERMEDIATE="$ISO.bz2"
		fi
  	echo "Downloading $ISO">&2	
		echo "curl --location --output \"$INTERMEDIATE\" \"$URL\""
	
		curl --fail --location --output $INTERMEDIATE "$URL"

		if [ "$?" != "0" ]; then
			echo "XXX Cannot fetch $ISO from">&2
			echo "XXX $URL from">&2
			exit 1
		fi

		if [ "$BUNZIPISO" = "1" ]; then
			bunzip2 $INTERMEDIATE
		fi
		
	fi
fi

INSTALLFLAGS=""
NETUSER="-net user"
NETNIC="-net nic"

if [ "$NOIPV6" != "" ]; then
	NETUSER="$NETUSER,ipv6=no"
fi

if [ "$SSHPORT" != "" ]; then
	NETUSER="$NETUSER,hostfwd=tcp::${SSHPORT}-:22"
fi


case $ARCH in
	i386|amd64|hppa)
	QEMUFLAGS="-hda $IMAGE"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-cdrom $ISO"
	;;
	prep)
	QEMUFLAGS="$OFWBOOT $IMAGE" # XXX
	INSTALLFLAGS="-cdrom $ISO" # CD is needed for regular running...
	  ;;
	evbppc)
	QEMUFLAGS="$OFWBOOT $IMAGE" # XXX
	INSTALLFLAGS="-cdrom $ISO" # CD is needed for regular running...
	CURSES="-nographic"
	  ;;
	evbarm)
	QEMUFLAGS="$OFWBOOT $IMAGE" # XXX
	INSTALLFLAGS="-cdrom $ISO" # CD is needed for regular running...
	CURSES="-nographic"
	  ;;

  macppc|powerpc)
	# I need the ISO to boot from after installation
	#
	[ "$SETUP" = "0" ] && echo "### At Boot:  type  netbsd.macppc -a">&2
	[ "$SETUP" = "1" ] && OFWBOOT="-prom-env boot-device=cd:,\\ofwboot.xcf"
	QEMUFLAGS="$OFWBOOT $IMAGE" 
	INSTALLFLAGS="-cdrom $ISO" # CD is needed for regular running...
  ;;
	sparc64)
	QEMUFLAGS="-drive file=$IMAGE,if=ide,bus=0,unit=0"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-drive file=$ISO,format=raw,if=ide,bus=1,unit=0,media=cdrom,readonly=on"
	;;
	sparc)
	QEMUFLAGS="$OFWBOOT -drive file=$IMAGE,if=scsi,bus=0,unit=0,media=disk"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-drive file=$ISO,format=raw,if=scsi,bus=0,unit=2,media=cdrom,readonly=on"
  ;;
	alpha)
	QEMUFLAGS="$OFWBOOT -hda $IMAGE"
	[ "$SETUP" = "1" ] && INSTALLFLAGS="-cdrom $ISO"
	;;
	*)
		# Crash out!
		echo "QEMUFlags case - $OS/$ARCH - I should not have been reached!">&2
		exit 1
	;;
esac

[ "$ONLYGETISO" = "1" ] && echo "Exiting - only getting iso" && exit 0

COMMAND="qemu-system-$EMU $EXTRAFLAGS $MEMORY $CURSES $INSTALLFLAGS $NETUSER $NETNIC $BOOT $QEMUFLAGS"

SCRIPT="boot.sh"
[ "$SETUP" = "1" ] && SCRIPT="install.sh"

echo "#!/bin/sh" >lastboot.sh
echo "# This is an experiment" >>lastboot.sh
echo "# Last boot was with:" >>lastboot.sh
echo "$COMMAND" >> lastboot.sh

cp lastboot.sh $SCRIPT

echo "Starting emulator"
echo "$COMMAND"
sleep 2
$COMMAND
