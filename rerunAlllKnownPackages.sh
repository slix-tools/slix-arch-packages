#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2023 S. G. Gottlieb <info.simon@gottliebtfreitag.de>
# SPDX-License-Identifier: CC0-1.0

set -Eeuo pipefail

pkgs=$(cat local/root/.cache/allreadyBuild.txt | cut -d ' ' -f 1 | sort -u)
./runInDocker.sh ${pkgs}
