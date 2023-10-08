#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

mkdir -p {cache,index}
docker run --cap-add SYS_ADMIN --device /dev/fuse -it --rm -v $(pwd)/cache:/var/cache/pacman/pkg -e SLIX_INDEX=/slix-index/index -v $(pwd)/index:/slix-index slix-arch /code/startup.sh "$@"
