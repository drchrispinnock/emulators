#!/bin/sh

TARGET=$HOME/VM/Qemu/NetBSD/arm64
SIZE=10g

NETBSD="http://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-9/latest/evbarm-aarch64/binary/gzimg/arm64.img.gz"
QEMUFIRM="http://snapshots.linaro.org/components/kernel/leg-virt-tianocore-edk2-upstream/latest/QEMU-AARCH64/RELEASE_GCC5/QEMU_EFI.fd"

# https://wiki.netbsd.org/ports/evbarm/qemu_arm/


# Create the directory
mkdir -p $TARGET
cd $TARGET

curl -L --output arm64.img.gz $NETBSD
curl -L --output QEMU_EFI.fd $QEMUFIRM

gunzip arm64.img.gz
qemu-img resize arm64.img $SIZE
mv arm64.img netbsd-disk-arm64.img

