#!/usr/bin/env bash

set -Eeuo pipefail

if [ -z "${SLIX_INDEX}" ]; then
    echo "Set SLIX_INDEX to path of index.db"
    exit 1;
fi

name=${1}
shift

if [ "${1:-}" == "--clean" ]; then
    shift;
    rm allreadyBuild.txt
fi

if [ $# -gt 0 ]; then
    echo ./build.sh ${@}
fi
exit

if [ -e "allreadyBuild.txt" ] && [ $(cat allreadyBuild.txt | grep "^${name}$" | wc -l) -gt 0 ]; then
    exit 0
fi

yq -r '.[]
        | select(.name == "'${name}'")
        | [  "name=" + .name
            , "deps=\"" + if has("deps") then .deps | join(" ") else "" end + "\""
            , "archpkg=" + if has("archpkg") then .archpkg else .name end
            , "defaultcmd="
        ] | join("\n")
    ' packages.yaml > tmp.src
source tmp.src
rm tmp.src

./preparePackage.sh ${name} ${archpkg} "${deps}"

yq -r '.[]
        | select(.name == "'${name}'")
        | if has("extraSteps") then .extraSteps else "" end
    ' packages.yaml > tmp_extraSteps.src
. ./tmp_extraSteps.src
rm tmp_extraSteps.src

./finalizePackage.sh ${name} ${archpkg} "${defaultcmd}"
