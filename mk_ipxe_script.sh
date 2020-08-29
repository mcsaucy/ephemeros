#!/bin/bash

set -e

key_path="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa.pub}"
if ! KEY=$(< "$key_path"); then
    echo "!!! Couldn't find ${key_path}. Set SSH_KEY_PATH to a pub key path." >&2
    exit 1
fi

kernel_params=(
    "initrd=flatcar_production_pxe_image.cpio.gz"
    "flatcar.first_boot=1"
    "sshkey=\"$KEY\""
    "ignition.config.url=${IGN_PATH:-https://raw.githubusercontent.com/mcsaucy/ephemeros/master/ignition.ign}"
)

if [[ -n "$NODE_HOSTNAME" ]]; then
    kernel_comandline+=( "hostname=$NODE_HOSTNAME" )
fi

echo "#!ipxe

dhcp
set base-url http://stable.release.flatcar-linux.net/amd64-usr/current
kernel \${base-url}/flatcar_production_pxe.vmlinuz ${kernel_params[*]}
initrd \${base-url}/flatcar_production_pxe_image.cpio.gz
boot"
