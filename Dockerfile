FROM archlinux:base

RUN pacman -Syu --noconfirm perl
RUN perl -i -p -e 's/^NoExtract += +.*$//' /etc/pacman.conf
# Reinstall all packages with all files
RUN pacman -S --noconfirm $(pacman -Q | awk '{print $1}')
RUN pacman -S --noconfirm yq fuse2 fmt glibc

# Installing slix
RUN curl https://slix-tools.de/releases/slix-bootstrap-pkg-latest.tar.zst -o slix-bootstrap-pkg.tar.zst
RUN tar -xaf slix-bootstrap-pkg.tar.zst && rm slix-bootstrap-pkg.tar.zst
COPY code /code

RUN . /slix-bootstrap-pkg/activate; \
    mkdir -p /root/.local/state/slix/packages && \
    slix -Syf /code/startup.slix

#source slix-bootstrap-pkg/activate
