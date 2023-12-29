#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

cp -a --remove-destination data/gcc12/gcc ${ROOTFS}/usr/bin/gcc
cp -a --remove-destination data/gcc12/g++ ${ROOTFS}/usr/bin/g++
