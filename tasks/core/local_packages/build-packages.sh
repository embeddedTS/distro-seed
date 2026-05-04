#!/bin/bash -e

INPUTS="${DS_WORK}/package-inputs"
PACKAGES="${DS_WORK}/packages"
BUILD_ROOT="$(mktemp -d /tmp/ds-packages.XXXXXX)"

cleanup() {
    rm -rf "$BUILD_ROOT"
}
trap cleanup EXIT

package_sort_key() {
    path="$1"
    name="$(basename "$path")"
    if [[ "$name" =~ ^([0-9]+)- ]]; then
        printf '%010d\t%s\n' "${BASH_REMATCH[1]}" "$path"
    else
        printf '9999999999\t%s\n' "$path"
    fi
}

package_name() {
    basename "$1" \
        | sed -E 's/^[0-9]+-//' \
        | tr '[:upper:]_' '[:lower:]-' \
        | sed -E 's/[^a-z0-9.+-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' \
        | sed 's/^/distro-seed-/'
}

package_version() {
    raw="$1"
    raw="${raw%%[$'\r\n']*}"
    raw="${raw#"${raw%%[![:space:]]*}"}"
    raw="${raw%"${raw##*[![:space:]]}"}"
    if [[ "$raw" =~ ^[vV][0-9] ]]; then
        raw="${raw:1}"
    fi
    raw="$(printf '%s' "$raw" | sed -E 's/[^A-Za-z0-9.+~]+/+/g; s/[+][+]+/+/g; s/^[+]//; s/[+]$//')"
    if [[ ! "$raw" =~ ^[0-9] ]]; then
        raw="0.0.1${raw:++$raw}"
    fi
    printf '%s\n' "${raw:-0.0.1}"
}

build_package() {
    input="$1"
    input_name="$(basename "$input")"
    if [[ ! -f "$input/data.tar" && ! -f "$input/control.tar" ]]; then
        return
    fi

    name="$(package_name "$input")"
    version="0.0.1"

    pkgroot="$BUILD_ROOT/$input_name"
    controlroot="$BUILD_ROOT/$input_name-control"
    rm -rf "$pkgroot"
    rm -rf "$controlroot"
    install -d "$pkgroot/DEBIAN"
    install -d "$controlroot"

    if [[ -f "$input/data.tar" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$pkgroot" -xf "$input/data.tar"
    fi
    if [[ -f "$input/control.tar" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$controlroot" -xf "$input/control.tar"
    fi

    if [[ -f "$controlroot/version" ]]; then
        version="$(package_version "$(cat "$controlroot/version")")"
    fi
    if ! dpkg --validate-version "$version" >/dev/null 2>&1; then
        version="0.0.1"
    fi

    cat > "$pkgroot/DEBIAN/control" <<EOF
Package: $name
Version: $version
Architecture: $DS_TARGET_ARCH
Maintainer: distro-seed <distro-seed@example.invalid>
Section: misc
Priority: optional
Description: distro-seed generated package for $input_name
 Generated from distro-seed task $input_name.
EOF

    for script in preinst postinst prerm postrm; do
        if [[ -f "$controlroot/$script" ]]; then
            install -m 755 "$controlroot/$script" "$pkgroot/DEBIAN/$script"
        fi
    done

    dpkg-deb --root-owner-group --build "$pkgroot" "$PACKAGES/$input_name.deb" >/dev/null
}

install -d "$PACKAGES"
rm -f "$PACKAGES"/*.deb

shopt -s nullglob
{
    for input in "$INPUTS"/*/; do
        package_sort_key "$input"
    done
} | sort -n -k1,1 | cut -f2- | while IFS= read -r input; do
    build_package "$input"
done
