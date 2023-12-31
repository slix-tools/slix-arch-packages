#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

name=${1}
shift

packagemanager="${1}"
shift

archpkg=${1}
shift

deps="${1}"
shift

target=${name}

if [ -z "${SLIX_INDEX}" ]; then
    echo "Set SLIX_INDEX to path of index.db"
    exit 1;
fi

#if [ -e "${HOME}/.cache/allreadyBuild.txt" ] && [ $(cat ${HOME}/.cache/allreadyBuild.txt | grep "^${name}$" | wc -l) -gt 0 ]; then
#    exit 0
#fi

# Build all dependencies
for d in $deps; do
    if [ $d == slix-ld ]; then
        true
    else
        ./build.sh $d
    fi
done

# prepare root folder
root=${TMP}/${target}/rootfs
if [ -e ${root} ]; then
    rm -rf "${root}"
fi
mkdir -p ${root}

# prepare meta folder
meta=${TMP}/${target}/meta
if [ -e ${meta} ]; then
    rm -rf "${meta}"
fi
mkdir -p ${meta}

# query dependencies and create a dependency file
echo -n "" > ${meta}/dependencies_unsorted.txt
for d in $deps; do
    latest="$(slix index info ${SLIX_INDEX} --name ${d} | tail -n 1 || true)"
    if [ -z "${latest}" ]; then
        echo "$name dependency $d is missing"
        exit 1
    fi
    echo ${latest} >> ${meta}/dependencies_unsorted.txt
    slix index info ${SLIX_INDEX} --name ${d} --dependencies >> ${meta}/dependencies_unsorted.txt
done
cat ${meta}/dependencies_unsorted.txt | sort | uniq > ${meta}/dependencies.txt
rm ${meta}/dependencies_unsorted.txt


echo "0" > ${TMP}/${target}/requiresSlixLD.txt
${packagemanager} -Ql ${archpkg} | awk '{ print $2; }' | (
    while IFS='$' read -r line; do
        if [ -d $line ] && [ ! -h $line ]; then
            mkdir -p ${root}/${line:1}
        elif [ -e $line ]; then
            if [ ! -r $line ]; then
                echo "no read access for ${line}"
                continue
            fi
            cp -a ${line} ${root}/${line:1}

            ############################
            # sanity check of every file
            ############################

            # if absolute sym link, change to relative
            if [ -L ${root}/${line:1} ]; then
                l=$(readlink ${root}/${line:1})
                if [ ${l:0:1} == "/" ]; then
                    l=${l:1}
                    echo linking ${root}/${l} to ${root}/${line:1}
                    ln -rsf ${root}/${l} ${root}/${line:1}
                fi
            fi

            # Fix non sym link executables
            if [ ! -L ${root}/${line:1} ] && [ -x ${root}/${line:1} ]; then
                t=$(file -b -h --mime-type ${root}/${line:1})

                # patch ld-linux.so.2 (interpreter of binaries)
                if [ "${t}" == "application/x-executable" ] \
                     || [ "${t}" == "application/x-pie-executable" ]; then
                    file="$(basename "${line}")"
                    dir="$(dirname "${line}")"
                    mv ${root}${dir}/${file} ${root}${dir}/.slix-ld-${file}
                    ln -sr ${root}/usr/bin/slix-ld ${root}${dir}/${file}
                    echo "1" > ${TMP}/${target}/requiresSlixLD.txt

                # patch shell scripts
                elif [ "${t}" == "text/x-shellscript" ] \
                    || [ "${t}" == "text/x-script.python" ] \
                    || [ "${t}" == "text/x-perl" ]; then
                    inter=$(head -n 1 ${root}/${line:1})
                    if [ "${inter:0:15}" == "#!/usr/bin/env " ] \
                        || [ "${inter:0:16}" == "#! /usr/bin/env " ]; then
                        true; # nothing todo
                    elif [ "${inter}" == "#!/bin/sh" ] \
                        || [ "${inter}" == "#! /bin/sh" ] \
                        || [ "${inter}" == "#!/bin/sh -" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env sh#' ${root}/${line:1}
                    elif [ "${inter}" == "#!/bin/bash" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env bash#' ${root}/${line:1}
                    elif [ "${inter}" == "#!/usr/bin/bash" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env bash#' ${root}/${line:1}
                    elif [ "${inter}" == "#!/bin/zsh" ] \
                        || [ "${inter}" == "#!/usr/local/bin/zsh" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env zsh#' ${root}/${line:1}
                    elif [ "${inter}" == "#!/usr/bin/python" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env python#' ${root}/${line:1}
                    elif [ "${inter:0:17}" == "#!/usr/bin/python" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env '${inter:11}'#' ${root}/${line:1}
                    elif [ "${inter}" == "#! /usr/bin/perl" ] \
                        || [ "${inter}" == "#!/usr/bin/perl" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env perl#' ${root}/${line:1}
                    elif [ "${inter}" == "#! /usr/bin/perl -w" ] \
                        || [ "${inter}" == "#!/usr/bin/perl -w" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env -S perl -w#' ${root}/${line:1}
                    elif [ "${inter}" == "#! /usr/bin/perl -w -s" ] \
                        || [ "${inter}" == "#!/usr/bin/perl -w -s" ]; then
                        sed -i '1s#.*#\#!/usr/bin/env -S perl -w -s#' ${root}/${line:1}
                    else
                        echo "${root}/${line:1} needs fixing, unexpected shell interpreter: ${inter}"
                    fi
                elif [ "${t:0:7}" == "text/x-" ]; then
                    inter=$(head -n 1 ${root}/${line:1})
                    echo "${root}/${line:1} needs fixing, unknown script type ${t}, guessing interpreter to be ${inter}"
                fi
            fi
        else
            echo "what is this? ${line}"
        fi
    done
)
requiresSlixLD=$(cat ${TMP}/${target}/requiresSlixLD.txt)
rm ${TMP}/${target}/requiresSlixLD.txt


hasLdD=0
for d in $deps; do
    if [ "$d" == "glibc" ]; then
        hasLdD=1
    fi
done

# this complaints if something seems odd between requirement of slix ld and actually using slix-ld
if [ ${requiresSlixLD} -eq 1 ] && [ ${hasLdD} -eq 0 ]; then
    echo "requirement of slix-ld for ${name} unclear: ${hasLdD} and ${requiresSlixLD}"
    true
fi
