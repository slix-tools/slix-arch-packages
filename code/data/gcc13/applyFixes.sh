#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

cp -a --remove-destination data/gcc13/gcc ${TMP}/${name}/rootfs/usr/bin/gcc
cp -a --remove-destination data/gcc13/g++ ${TMP}/${name}/rootfs/usr/bin/g++
mv ${TMP}/${name}/rootfs/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.1/cc1     ${TMP}/${name}/rootfs/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.1/.slix-cc1
mv ${TMP}/${name}/rootfs/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.1/cc1plus ${TMP}/${name}/rootfs/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.1/.slix-cc1plus
cp -a --remove-destination data/gcc13/cc1     ${TMP}/${name}/rootfs/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.1/cc1
cp -a --remove-destination data/gcc13/cc1plus ${TMP}/${name}/rootfs/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.1/cc1plus
