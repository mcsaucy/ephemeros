#!/bin/bash
set -e
shopt -s nullglob


function log() {
    echo -e "\e[32m$*\e[0m" >&2
}

function error() {
    echo -e "\e[31m$*\e[0m" >&2
}

function build_ipxe() {
    (
        cd "$OUT"
        git clone git://git.ipxe.org/ipxe.git
        cd ipxe/src
        make -j "$(nproc)" bin/ipxe.usb EMBED="$HERE/flatcar.ipxe"
        log "Built $PWD/bin/ipxe.usb"
    ) >&2
    echo "$OUT/ipxe/src/bin/ipxe.usb"
}

function unmount() {
    log "unmounting $DISK (and associated partitions)"
    umount -q "$DISK" "$DISK"? || :
}


HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OUT="$(mktemp -d /tmp/pxe_build_o0rt.cloud_XXXXXX)"
log "Using $OUT for temp storage"

DISK="$1"
if [[ -z "$DISK" ]]; then
    error "Usage: build_pxe_stick.sh /dev/sdX"
    exit 1
fi

if [[ ! -w "$DISK" ]]; then
    error "$DISK is not writeable. Check your privilege, and that it exists."
    exit 2
fi

log "$DISK presently looks like this:"
log "$(lsblk "$DISK")"
read -p "We're gonna zap <$DISK>! Type \"i don't want that data\" to continue. >>> "
if [[ "$REPLY" != "i don't want that data" ]]; then
    error "Aborting."
    exit 2
fi

unmount

IPXE_IMG="$(build_ipxe)"
dd if="$IPXE_IMG" of="$DISK"
log "dd'd image to $DISK" >&2

log "Adding a partition for secrets to $DISK"
parted "$DISK" mkpart primary ext4 512MB 1GB
log "We don't know the name of the actual partition we just made is,"
log "so we're just gonna assume it's ${DISK}1."
log

partprobe

log "If you're running this on a drive that was previously provisioned with"
log "this script, you may find a scary message regarding an existing fs. "
log "This is caused by our parted invocation lining things up just right such"
log "that the existing fs is still roughly in tact."
log
log "It's likely safe to proceed here."
log "Making an ext4 volume on ${DISK}1 called 'secrets'."
mkfs.ext4 -L secrets "${DISK}1"

sudo mkdir "$OUT/mountpoint"
log "mounting secrets volume @ $OUT/mountpoint"
mount "${DISK}1" "$OUT/mountpoint"
SECRETS="$OUT/mountpoint"

log "Writing some placeholder values to secrets files"
echo "TODO: update me with something real" > "$SECRETS/k3s_token"
echo "" > "$SECRETS/k3s_datastore_endpoint"
echo "" > "$SECRETS/papertrail_host"
echo "" > "$SECRETS/papertrail_port"


