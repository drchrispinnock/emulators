#!/bin/sh

GRAPHICS="-nographic"
#GRAPHICS="-device ramfb -device nec-usb-xhci,id=xhci -device usb-mouse,bus=xhci.0 -device usb-kbd,bus=xhci.0"

cd $HOME/VM/Qemu/NetBSD/arm64
qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
      -drive if=none,file=netbsd-disk-arm64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
      -netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
      -bios QEMU_EFI.fd $GRAPHICS
