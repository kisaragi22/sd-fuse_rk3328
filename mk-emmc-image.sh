#!/bin/bash

# Copyright (C) Guangzhou FriendlyARM Computer Tech. Co., Ltd.
# (http://www.friendlyarm.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can access it online at
# http://www.gnu.org/licenses/gpl-2.0.html.

function usage() {
       echo "Usage: $0 <debian|buildroot|android7|android8|friendlywrt|friendlycore-arm64|friendlydesktop-arm64|lubuntu|eflasher>"
       exit 0
}

if [ $# -eq 0 ]; then
    usage
fi

# ----------------------------------------------------------
# Get platform, target OS

true ${SOC:=rk3328}
true ${TARGET_OS:=${1,,}}

case ${TARGET_OS} in
debian* | buildroot* | android7 | android8 | friendlycore* | friendlydesktop* | lubuntu* | friendlywrt)
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 0
esac

download_img() {
    local RKPARAM=$(dirname $0)/${1}/parameter.txt
    case ${1} in
    eflasher)
        RKPARAM=$(dirname $0)/${1}/partmap.txt
        ;;
    esac

    if [ -f "${RKPARAM}" ]; then
        echo ""
    else
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image not found for ${1}
----------------
you may download them from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called images-for-eflasher, for example:
    tar xvzf /path/to/NETDISK/images-for-eflasher/${ROMFILE}
----------------
Or, download from http (Y/N)?
EOF
        while read -r -n 1 -t 3600 -s USER_REPLY; do
            if [[ ${USER_REPLY} = [Nn] ]]; then
                echo ${USER_REPLY}
                exit 1
            elif [[ ${USER_REPLY} = [Yy] ]]; then
                echo ${USER_REPLY}
                break;
            fi
        done

        if [ -z ${USER_REPLY} ]; then
            echo "Cancelled."
            exit 1
        fi
        ./tools/get_rom.sh ${1} || exit 1
    fi
}

download_img ${TARGET_OS}
download_img eflasher

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo "$0" "$@"
	exit
fi

./mk-sd-image.sh eflasher && \
	./tools/fill_img_to_eflasher out/${SOC}-eflasher-$(date +%Y%m%d).img ${SOC} $@ && { 
		rm -f out/${SOC}-eflasher-$(date +%Y%m%d).img
		mkdir -p out/images-for-eflasher
		tar czf out/images-for-eflasher/${TARGET_OS}-images.tgz ${TARGET_OS}
		echo "all done."
	}


