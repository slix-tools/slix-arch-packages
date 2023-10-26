#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

echo "Entering Docker"
export MAKEFLAGS="-j8"
if [ "$1" == "--bash" ]; then
    bash
    exit
fi

# Installing all the packages
. /slix-bootstrap-pkg/activate
slix -Sui /code/startup.slix


# Starting an slix environment
eval "$(slix env /code/startup.slix --stack --allow_other --mount /slix-fs)"

# Starting bash in user space
if [ "$1" == "--user" ]; then
    pacman -Syyu --noconfirm
    export INSTALL_BEFORE_PACKAGING=1
    cd
    sudo -u aur --preserve-env=MAKEFLAGS bash
    exit
fi

if [ ! -e ${SLIX_INDEX} ]; then
    slix index init ${SLIX_INDEX}
    slix index add ${SLIX_INDEX} --package /code/slix-ld.gar
fi
pacman -Syyu --noconfirm
export INSTALL_BEFORE_PACKAGING=1
/code/build.sh "$@"
