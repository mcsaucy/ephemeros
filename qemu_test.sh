#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: [NO_CURSES=1] ./qemu_test.sh /dev/sdX" >&2
    exit 1
fi

displaymode="--curses"
if [[ -n "$NO_CURSES" ]]; then
    displaymode="--vga=virtio"
fi

sudo qemu-system-x86_64 \
    -hda "$1" \
    -smp 2 -m 4096 \
    "$displaymode" \
    -net nic,model=virtio -net user,hostfwd=tcp::2222-:22
