## Docker
Build container by running:

```
docker build . -t slix-arch
```

Running the container
```
mkdir -p cache
docker run -it --rm -v $(pwd)/cache:/var/cache/pacman/pkg -e SLIX=_INDEX=/slix-index -v $(pwd)/index:/slix-index slix-arch bash
```
