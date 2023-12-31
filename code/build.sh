#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if [ -z "${SLIX_INDEX}" ]; then
    echo "Set SLIX_INDEX to path of index.db"
    exit 1;
fi

if [ "${1:-}" == "--clean" ]; then
    shift;
    rm -f ${HOME}/.cache/allreadyBuild.txt
fi

name=${1}
shift

export TMP=/tmp


if [ $# -gt 0 ]; then
    ./build.sh ${@}
fi

yq -r '.[]
        | select(.name == "'${name}'")
        | [  "pkgname=" + .name
            , "deps=\"" + if has("deps") then .deps | join(" ") else "" end + "\""
            , "packagemanager=" + if has ("packagemanager") then .packagemanager else "pacman" end
            , "archpkg=" + if has("archpkg") then .archpkg else .name end
            , "defaultcmd=\"" + if has("defaultcmd") then .defaultcmd else "" end +"\""
        ] | join("\n")
    ' packages.yaml > ${TMP}/tmp.src
source ${TMP}/tmp.src
rm ${TMP}/tmp.src
if [ "${pkgname:-}" == "" ]; then
    echo "Error: unknown package \"${name}\""
    exit 1
fi

if [ "${packagemanager}" == "yay" ]; then
    packagemanager="sudo -u aur --preserve-env=MAKEFLAGS yay"
fi

archpkg_version=$(${packagemanager:-pacman} -Si "${archpkg}" | grep "Version" | cut -d ':' -f 2- | cut -b 2-)
fullVersionName="${name} ${archpkg} ${archpkg_version}"
if [ -e "${HOME}/.cache/allreadyBuild.txt" ] && [ $(cat ${HOME}/.cache/allreadyBuild.txt | grep "^${fullVersionName}$" | wc -l) -gt 0 ]; then
    exit 0
fi

echo "installing/packaging: ${name}"
if [ "${INSTALL_BEFORE_PACKAGING:-0}" -eq 1 ]; then
    ${packagemanager} -S --noconfirm --needed "${archpkg}"
fi

description=$(${packagemanager} -Si "${archpkg}" | grep "Description" | cut -d ':' -f 2- | cut -b 2-)

./preparePackage.sh ${name} "${packagemanager}" ${archpkg} "${deps}"

# New way, run applyFixes.sh
export ROOTFS=${TMP}/${name}/rootfs/
if [ -e "data/${name}/applyFixes.sh" ]; then
    source ./data/${name}/applyFixes.sh
fi

./finalizePackage.sh ${name} "${packagemanager}" ${archpkg} "${defaultcmd}" "${description}"
echo ${fullVersionName} >> ${HOME}/.cache/allreadyBuild.txt
