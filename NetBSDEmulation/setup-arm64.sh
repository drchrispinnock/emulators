#!/bin/sh

TARGET=$HOME/Qemu/NetBSD/arm64
SIZE=10g

NETBSD="http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-9/latest/evbarm-aarch64/binary/gzimg/arm64.img.gz"
QEMUFIRM="http://snapshots.linaro.org/components/kernel/leg-virt-tianocore-edk2-upstream/latest/QEMU-AARCH64/RELEASE_GCC5/QEMU_EFI.fd"

# https://wiki.netbsd.org/ports/evbarm/qemu_arm/


# Create the directory
mkdir -p $TARGET
cd $TARGET

URL="https://cdn.netbsd.org/pub/NetBSD/NetBSD-$VERS/images/$ISO"

curl --output arm64.img.gz $NETBSD
curl --output QEMU_EFI.fd $QEMUFIRM

gunzip arm64.img.gz
qemu-img resize arm64.img $SIZE


