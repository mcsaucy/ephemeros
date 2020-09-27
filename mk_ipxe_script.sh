#!/bin/bash

set -e

key_path="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa.pub}"
if ! KEY=$(< "$key_path"); then
    echo "!!! Couldn't find ${key_path}. Set SSH_KEY_PATH to a pub key path." >&2
    exit 1
fi

latest_pxe=https://latest-fcos.herokuapp.com/stable/artifacts/x86_64/metal/pxe

kernel_params=(
    "coreos.live.rootfs_url=$latest_pxe/rootfs"
    "ignition.platform.id=metal"
    "ignition.firstboot"
    "ignition.config.url=${IGN_PATH:-https://raw.githubusercontent.com/mcsaucy/ephemeros/fcos/ignition.ign}"
    "sshkey=\"$KEY\""
    "systemd.unified_cgroup_hierarchy=0"
)

if [[ -n "$NODE_HOSTNAME" ]]; then
    kernel_params+=( "hostname=$NODE_HOSTNAME" )
fi

echo "#!ipxe

dhcp
set base-url $latest_pxe
kernel \${base-url}/kernel ${kernel_params[*]}
initrd \${base-url}/initramfs
boot"
