#!/bin/bash
set -eux

qemu-system-x86_64 -serial stdio \
                   -drive format=raw,file=disk-encrypted.img \
                   -m 2G \
                   --enable-kvm \
                   -net nic,model=rtl8139 \
                   -net user,hostfwd=tcp:127.0.0.1:2222-:22 \
