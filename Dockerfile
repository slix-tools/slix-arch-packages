# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

FROM archlinux:base

RUN pacman -Syu --noconfirm perl
RUN perl -i -p -e 's/^NoExtract += +.*$//' /etc/pacman.conf
# Reinstall all packages with all files
RUN pacman -S --noconfirm $(pacman -Q | awk '{print $1}')
RUN pacman -Sy --noconfirm sudo git
RUN useradd -m aur && \
    passwd -d aur && \
    echo 'aur ALL=(ALL) ALL' > /etc/sudoers.d/aur

# Installing slix
RUN curl https://slix-tools.de/releases/slix-bootstrap-pkg-latest.tar.zst -o slix-bootstrap-pkg.tar.zst
RUN tar -xaf slix-bootstrap-pkg.tar.zst && rm slix-bootstrap-pkg.tar.zst
COPY code /code

RUN . /slix-bootstrap-pkg/activate; \
    mkdir -p /root/.local/state/slix/packages && \
    slix -Syf /code/startup.slix
