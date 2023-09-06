#!/usr/bin/env bash
mkdir -p {cache,index}
docker run -it --rm -v $(pwd)/cache:/var/cache/pacman/pkg -e SLIX_INDEX=/slix-index/index -v $(pwd)/index:/slix-index slix-arch /code/startup.sh "$@"
