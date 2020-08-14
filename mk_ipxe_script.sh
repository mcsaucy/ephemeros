#!/bin/bash

KEY=$(cat ${SSH_KEY_PATH:-$HOME/.ssh/id_rsa.pub})

echo "#!ipxe

dhcp
set base-url http://stable.release.flatcar-linux.net/amd64-usr/current
kernel \${base-url}/flatcar_production_pxe.vmlinuz \
    initrd=flatcar_production_pxe_image.cpio.gz \
    flatcar.first_boot=1 \
    sshkey=\"$KEY\" \
    ignition.config.url=${IGN_PATH:-https://raw.githubusercontent.com/mcsaucy/ephemeros/master/ignition.ign}
initrd \${base-url}/flatcar_production_pxe_image.cpio.gz
boot"
