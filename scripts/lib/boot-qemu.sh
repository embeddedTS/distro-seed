# shellcheck shell=bash
# Architecture variables are supplied by the sourcing launcher.
# shellcheck disable=SC2154
# Shared by the ARMHF and ARM64 launchers; source this file.
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
image=""
display=(-nographic)
while (( $# )); do
    case "$1" in
        --graphics)
            display=(-display gtk -serial mon:stdio
                -device virtio-gpu-pci
                -device virtio-keyboard-pci -device virtio-tablet-pci)
            ;;
        -h|--help)
            echo "Usage: $0 [--graphics] [rootfs.ext4]"
            exit 0
            ;;
        -*) echo "Unknown option: $1" >&2; exit 1 ;;
        *)
            [[ -z "$image" ]] || { echo "Specify only one image" >&2; exit 1; }
            image="$1"
            ;;
    esac
    shift
done
image="${image:-$repo_dir/work/output/rootfs.ext4}"
[[ -f "$image" ]] || { echo "Image not found: $image" >&2; exit 1; }

tmp_dir="$(mktemp -d)"
cleanup() {
    if [[ -n "${GUESTFISH_PID:-}" ]]; then
        guestfish --remote exit >/dev/null 2>&1 || true
    fi
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

# One read-only appliance extracts both files without a host mount or sudo.
eval "$(guestfish --ro --format=raw -a "$image" -m /dev/sda --listen)"
[[ -n "${GUESTFISH_PID:-}" ]] || { echo "Unable to start guestfish" >&2; exit 1; }
for name in vmlinuz initrd.img; do
    path="/$name"
    if [[ "$(guestfish --remote is-file "$path" followsymlinks:true)" != true ]]; then
        path="/boot/$name"
    fi
    guestfish --remote download "$path" "$tmp_dir/$name"
done
guestfish --remote exit
unset GUESTFISH_PID

"$qemu" \
    -machine "$machine" -cpu "$cpu" -m 1G -smp 2 \
    -kernel "$tmp_dir/vmlinuz" -initrd "$tmp_dir/initrd.img" \
    -append 'root=/dev/vda rootfstype=ext4 rw rootwait console=ttyAMA0,115200' \
    -drive if=none,file="$image",format=raw,id=rootdisk \
    -device virtio-blk-device,drive=rootdisk \
    -netdev user,id=net0 -device virtio-net-device,netdev=net0 \
    "${display[@]}"
