#!/usr/bin/env bash
echo "Entering Docker"
export MAKEFLAGS="-j8"
if [ "$1" == "--bash" ]; then
    bash
    exit
fi
. /slix-bootstrap-pkg/activate
eval "$(slix env --stack /code/startup.slix --allow_other --mount /slix-fs)"

if [ ! -e ${SLIX_INDEX} ]; then
    slix index init ${SLIX_INDEX}
    slix index add ${SLIX_INDEX} --package /code/slix-ld.gar
fi
pacman -Syyu --noconfirm
export INSTALL_BEFORE_PACKAGING=1
/code/build.sh "$@"
