#!/bin/bash

set -e

if [ "${DS_TARGET_ARCH}" = "arm64" ]  ; then
    KERNEL_FILE=Image
    BOOT_CMD=booti
else
    KERNEL_FILE=zImage
    BOOT_CMD=bootz
fi
TMP_BOOT_SOURCE="${DS_TASK_PATH}/boot/boot.source"
[ ! -d "$(dirname ${TMP_BOOT_SOURCE})" ] && mkdir -p "$(dirname ${TMP_BOOT_SOURCE})"

cat > "${TMP_BOOT_SOURCE}" <<EOF
# mkimage -A arm -T script -C none -n 'boot' -d boot.source boot.scr

setenv bootargs "console=\${console} rootwait init=/sbin/init loglevel=4"

part uuid \${devtype} \${devnum}:\${distro_bootpart} bootuuid
if test -n "\${bootuuid}"; then
  setenv bootargs "\${bootargs} root=PARTUUID=\${bootuuid}"
fi

load \${devtype} \${devnum}:\${distro_bootpart} \${kernel_addr_r} \${prefix}${KERNEL_FILE} \
&& load \${devtype} \${devnum}:\${distro_bootpart} \${fdt_addr_r} \${prefix}\${fdtfile} \
&& echo "Booting \$DISTRO \$RELEASE from \${devtype} \${devnum}:\${distro_bootpart}..." \
&& ${BOOT_CMD} \${kernel_addr_r} - \${fdt_addr_r}
EOF

mkimage -A arm -T script -C none -n 'boot' \
        -d "${TMP_BOOT_SOURCE}" "${DS_OVERLAY}/boot/boot.scr"

if [[ "${CONFIG_DS_COMPONENT_DISTROBOOT_SCRIPTS_INSTALL_SOURCE}" == 'y' ]]; then
    install --target-directory="$DS_OVERLAY/boot/" "${TMP_BOOT_SOURCE}"
fi
