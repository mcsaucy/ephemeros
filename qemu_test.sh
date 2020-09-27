#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: [NO_CURSES=1] ./qemu_test.sh /dev/sdX" >&2
    exit 1
fi

displaymode=()
if [[ -n "$NO_CURSES" ]]; then
    displaymode=(-vga virtio)
else
    displaymode=(--curses)
fi

sudo qemu-system-x86_64 \
    -enable-kvm \
    -runas "$USER" \
    -cpu host \
    -hda "$1" \
    -smp 2 -m 8092 \
    -net nic,model=virtio -net user,hostfwd=tcp::2222-:22 \
    "${displaymode[@]}" 
