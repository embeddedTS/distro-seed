#!/bin/bash -e

INSTALL="$DS_WORK/rootfs/"
install -d "$INSTALL"

PACKAGELIST_FILE="packagelist/${CONFIG_DS_PACKAGELIST}"

if [[ -n "$CONFIG_DS_PACKAGELIST" && ! -e "$PACKAGELIST_FILE" ]]; then
  echo "Specified packagelist \"$PACKAGELIST_FILE\" doesn't exist!" >&2
  exit 1
fi

# ----- Distro-specific defaults -----
if [[ "$DS_DISTRO" == "debian" ]]; then
  KEYRING_NAME="debian-archive-keyring"
  KEYRING_PATH="/usr/share/keyrings/debian-archive-keyring.gpg"
  SOURCE_URL="http://deb.debian.org/debian"
  if [[ "$DS_RELEASE" == "bullseye" ]]; then
    DEB_COMPONENTS="main contrib non-free"
  else
    DEB_COMPONENTS="main contrib non-free non-free-firmware"
  fi
elif [[ "$DS_DISTRO" == "ubuntu" ]]; then
  KEYRING_NAME="ubuntu-keyring"
  KEYRING_PATH="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
  SOURCE_URL="http://www.ports.ubuntu.com/ubuntu-ports"
  DEB_COMPONENTS="main universe multiverse"
else
  echo "Unknown distro \"$DS_DISTRO\"!" >&2
  exit 1
fi

# Optional custom mirror override
if [[ "$CONFIG_DS_CUSTOM_APT_MIRROR" == "y" && -n "$CONFIG_DS_CUSTOM_APT_URL" ]]; then
  SOURCE_URL="$CONFIG_DS_CUSTOM_APT_URL"
fi

tmp_combined="$(mktemp)"
tmp_work="$(mktemp)"

if [[ -n "$CONFIG_DS_PACKAGELIST" ]]; then
  cat "$PACKAGELIST_FILE" >> "$tmp_work"
fi

if [[ -d "$DS_WORK/packagelist" ]]; then
  for f in "$DS_WORK"/packagelist/*; do
    [[ -f "$f" ]] && { cat "$f" >> "$tmp_work"; echo >> "$tmp_work"; }
  done
fi

# Strip comments / blank lines, normalize whitespace
sed -e 's/#.*$//' -e '/^$/d' "$tmp_work" | tr -s '[:space:]' ' ' > "$tmp_combined"

# Unique, space-separated list
PKGS="$(tr ' ' '\n' < "$tmp_combined" | sort -u | paste -sd' ' -)"

rm -f "$tmp_work" "$tmp_combined"

# mmdebstrap uses the keyring from the host os, which may be a surprise.  This
# ensures that it is present. Since we run in a matching host container, this should always
# be the case.
if [[ ! -r "$KEYRING_PATH" ]]; then
  echo "Host is missing $KEYRING_NAME ($KEYRING_PATH). Installing helps mmdebstrap's first apt update." >&2
  echo "Try: sudo apt-get update && sudo apt-get install -y $KEYRING_NAME gnupg" >&2
  # We won’t exit; you can also pass --keyring explicitly below if you prefer.
fi

if [ "$DS_RELEASE" == "bullseye" ]; then
  mmdebstrap \
    --architectures="$DS_TARGET_ARCH" \
    --variant=custom \
    --components="$DEB_COMPONENTS" \
    --keyring="$KEYRING_PATH" \
    --include='?essential' \
    --include="apt ${PKGS}" \
    "$DS_RELEASE" "$INSTALL" "$SOURCE_URL"
else
  mmdebstrap \
    --architectures="$DS_TARGET_ARCH" \
    --variant=custom \
    --components="$DEB_COMPONENTS" \
    --keyring="$KEYRING_PATH" \
    --include='?essential' \
    --include='~prequired|~pimportant' \
    --include="apt ${PKGS}" \
    "$DS_RELEASE" "$INSTALL" "$SOURCE_URL"
fi

# Each distro's sourceslist.sh will set up a deb822 sources format file.
# at the time of writing mmdebstrap writes a traditional sources.list only
rm -rf "${INSTALL}/etc/apt/sources.list"
