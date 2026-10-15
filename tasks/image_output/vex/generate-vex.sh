#!/bin/bash -e

OUTPUT="${DS_WORK}/output"
VEX_PATH="${OUTPUT}/${DS_OUTPUT_BASENAME}.vex.json"
CYCLONEDX_PATH="${OUTPUT}/${DS_OUTPUT_BASENAME}.cdx.json"

db_args=()
if [[ -n "${CONFIG_DS_OUTPUT_VEX_DATABASE}" ]]; then
	database="${CONFIG_DS_OUTPUT_VEX_DATABASE}"
	if [[ ! -r "${database}" ]]; then
		echo "VEX database not readable: ${database}" >&2
		exit 1
	fi
else
	database="${DS_DL}/debsbom/security-tracker.json"
	install -d "$(dirname "${database}")"
	db_args+=(--update-db)
fi

vex_tmp="$(mktemp "${VEX_PATH}.XXXXXX")"
trap 'rm -f "${vex_tmp}"' EXIT

debsbom sec-scan \
	--db "${database}" \
	"${db_args[@]}" \
	--distro "${DS_RELEASE}" \
	--author "${CONFIG_DS_OUTPUT_VEX_AUTHOR}" \
	--product "urn:distro-seed:image:${DS_OUTPUT_BASENAME}" \
	--format vex \
	"${CYCLONEDX_PATH}" > "${vex_tmp}"

chmod 644 "${vex_tmp}"
mv "${vex_tmp}" "${VEX_PATH}"
