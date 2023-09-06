#!/bin/bash
echo "Entering Docker"
# Overwritting activate of slix-bootstrap (why is it broken?)
. /slix-bootstrap-pkg/activate

if [ "$1" == "--bash" ]; then
    bash
    exit
fi

if [ ! -e ${SLIX_INDEX} ]; then
    slix index init ${SLIX_INDEX}
    slix index add ${SLIX_INDEX} --package /code/slix-ld.gar
fi
export INSTALL_BEFORE_PACKAGING=1
/code/build.sh "$@"
