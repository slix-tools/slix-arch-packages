#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

name=${1}
shift

packagemanager=$"${1}"
shift

archpkg=${1}
shift

defaultcmd=${1}
shift

description=${1}
shift

if [ -z "${SLIX_INDEX}" ]; then
    echo "Set SLIX_INDEX to path of index.db"
    exit 1;
fi

#if [ -e "${HOME}/.cache/allreadyBuild.txt" ] && [ $(cat ${HOME}/.cache/allreadyBuild.txt | grep "^${name}$" | wc -l) -gt 0 ]; then
#    exit 0
#fi

version=$(${packagemanager} -Qi ${archpkg} \
    | grep -P "^Version" \
    | tr '\n' ' ' \
    | awk '{print $3}')

target=${name}

if [ -n "${defaultcmd}" ]; then
    echo "${defaultcmd}" > ${TMP}/${target}/meta/defaultcmd.txt
fi
echo "${name}" > ${TMP}/${target}/meta/name.txt
echo "${version}" > ${TMP}/${target}/meta/version.txt
echo "${description}" > ${TMP}/${target}/meta/description.txt

slix archive --input ${TMP}/${target} --output ${TMP}/${target}.gar
if [ $(cat ${TMP}/${target}/meta/dependencies.txt | grep Missing.gar | wc -l) -ge 1 ]; then
    echo "${target} is missing dependencies:"
    cat ${TMP}/${target}/meta/dependencies.txt | grep Missing.gar
    rm ${TMP}/${target}.gar
else
    slix index add ${SLIX_INDEX} --package ${TMP}/${target}.gar
    rm ${TMP}/${target}.gar
fi

rm -rf ${TMP}/${target}
