#!/usr/bin/env bash
echo "Entering Docker"
# Overwritting activate of slix-bootstrap (why is it broken?)
. /slix-bootstrap-pkg/activate
eval "$(slix env --stack /code/startup.slix)"

if [ "$1" == "--bash" ]; then
    bash
    exit
fi

if [ ! -e ${SLIX_INDEX} ]; then
    slix index init ${SLIX_INDEX}
    slix index add ${SLIX_INDEX} --package /code/slix-ld.gar
fi
pacman -Syyu --noconfirm
export INSTALL_BEFORE_PACKAGING=1
/code/build.sh "$@"
