#!/bin/bash
set -eux

qemu-system-x86_64 -serial stdio \
                   -drive format=raw,file=disk-unencrypted.img \
                   -m 2G \
                   --enable-kvm
