#!/usr/bin/env bash

set -Eeuo pipefail

name=${1}
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

if [ -e "allreadyBuild.txt" ] && [ $(cat allreadyBuild.txt | grep "^${name}$" | wc -l) -gt 0 ]; then
    exit 0
fi

version=$(pacman -Qi ${archpkg} \
    | grep -P "^Version" \
    | tr '\n' ' ' \
    | awk '{print $3}')

target=${name}

if [ -n "${defaultcmd}" ]; then
    echo "${defaultcmd}" > ${target}/meta/defaultcmd.txt
fi
echo "${name}" > ${target}/meta/name.txt
echo "${version}" > ${target}/meta/version.txt
echo "${description}" > ${target}/meta/description.txt

slix archive --input ${target} --output ${target}.gar
if [ $(cat ${target}/meta/dependencies.txt | grep Missing.gar | wc -l) -ge 1 ]; then
    echo "${target} is missing dependencies:"
    cat ${target}/meta/dependencies.txt | grep Missing.gar
    rm ${target}.gar
else
    slix index add ${SLIX_INDEX} --package ${target}.gar
    rm ${target}.gar
fi

echo ${name} >> allreadyBuild.txt
rm -rf ${target}