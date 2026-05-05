#!/bin/bash -e

INPUTS="${DS_WORK}/package-inputs"
PACKAGES="${DS_WORK}/packages"
BUILD_ROOT="$(mktemp -d /tmp/ds-packages.XXXXXX)"
PLACEHOLDER_VERSION="0.0.1~distroseed1"

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
    printf '%s\n' "$raw"
}

build_package() {
    input="$1"
    input_name="$(basename "$input")"
    if [[ ! -f "$input/data.tar" && ! -f "$input/debian.tar" ]]; then
        return
    fi

    name="$(package_name "$input")"
    version=""
    if [[ -f "$input/metadata.env" ]]; then
        source "$input/metadata.env"
        version="${DS_PKG_VERSION:-}"
    fi

    pkgroot="$BUILD_ROOT/$input_name"
    debianroot="$BUILD_ROOT/$input_name-debian"
    rm -rf "$pkgroot"
    rm -rf "$debianroot"
    install -d "$pkgroot/DEBIAN"
    install -d "$debianroot"

    if [[ -f "$input/data.tar" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$pkgroot" -xf "$input/data.tar"
    fi
    if [[ -f "$input/debian.tar" ]]; then
        tar --xattrs --xattrs-include='*' --acls --selinux --numeric-owner --sparse \
            -C "$debianroot" -xf "$input/debian.tar"
    fi

    if [[ -f "$debianroot/control" ]]; then
        install -m 644 "$debianroot/control" "$pkgroot/DEBIAN/control"
    else
        if [[ -z "$version" ]]; then
            echo "Warning: $name has no generated package version; using placeholder ${PLACEHOLDER_VERSION}" >&2
            version="$PLACEHOLDER_VERSION"
        fi
        version="$(package_version "$version")"
        if ! dpkg --validate-version "$version" >/dev/null 2>&1; then
            echo "Error: $name has invalid generated package version: $version" >&2
            return 1
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
    fi

    for script in preinst postinst prerm postrm; do
        if [[ -f "$debianroot/$script" ]]; then
            install -m 755 "$debianroot/$script" "$pkgroot/DEBIAN/$script"
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
