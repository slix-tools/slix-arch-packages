#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

cp -a --remove-destination data/gcc13/gcc ${TMP}/${name}/rootfs/usr/bin/gcc
cp -a --remove-destination data/gcc13/g++ ${TMP}/${name}/rootfs/usr/bin/g++
