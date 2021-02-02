#!/bin/sh

# Setup a FreeBSD emulator from scratch
#
ARCH=amd64
REL=12.2
ISO=FreeBSD-$VERS-$ARCH-disc1.iso
VM=FreeBSD-$VERS-$ARCH.qcow2

ISOURL="$BASEURL/$ARCH/$ARCH/ISO-IMAGES/$REL.xz"
VMURL="$BASEURL/VM-IMAGES/$VERS/$ARCH/Latest/$VM.xz"
