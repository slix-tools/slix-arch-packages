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
    rm -f allreadyBuild.txt
fi

name=${1}
shift


if [ $# -gt 0 ]; then
    ./build.sh ${@}
fi

if [ -e "allreadyBuild.txt" ] && [ $(cat allreadyBuild.txt | grep "^${name}$" | wc -l) -gt 0 ]; then
    exit 0
fi
yq -r '.[]
        | select(.name == "'${name}'")
        | [  "pkgname=" + .name
            , "deps=\"" + if has("deps") then .deps | join(" ") else "" end + "\""
            , "packagemanager=" + if has ("packagemanager") then .packagemanager else "pacman" end
            , "archpkg=" + if has("archpkg") then .archpkg else .name end
            , "defaultcmd=\"" + if has("defaultcmd") then .defaultcmd else "" end +"\""
        ] | join("\n")
    ' packages.yaml > tmp.src
source tmp.src
rm tmp.src
if [ "${pkgname:-}" == "" ]; then
    echo "Error: unknown package \"${name}\""
    exit 1
fi

if [ "${packagemanager}" == "yay" ]; then
    packagemanager="sudo -u aur --preserve-env=MAKEFLAGS yay"
fi

echo "installing/packaging: ${name}"
if [ "${INSTALL_BEFORE_PACKAGING:-0}" -eq 1 ]; then
    ${packagemanager} -S --noconfirm --needed "${archpkg}"
fi

description=$(${packagemanager} -Si "${archpkg}" | grep "Description" | cut -d ':' -f 2- | cut -b 2-)

./preparePackage.sh ${name} "${packagemanager}" ${archpkg} "${deps}"

yq -r '.[]
        | select(.name == "'${name}'")
        | if has("extraSteps") then .extraSteps else "" end
    ' packages.yaml > tmp_extraSteps.src
. ./tmp_extraSteps.src
rm tmp_extraSteps.src

./finalizePackage.sh ${name} "${packagemanager}" ${archpkg} "${defaultcmd}" "${description}"
