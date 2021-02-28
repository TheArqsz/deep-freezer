#!/usr/bin/env bash

set -Eeuo pipefail
# trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-u]

Deep freeze your Debian-based distro.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-u, --unfreeze  Unfreeze your system
EOF
    exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    rm /tmp/lethe.deb 2>/dev/null
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

trap ctrl_c INT

ctrl_c() {
    echo
    msg "${RED}####${NOFORMAT} Script interrupted ${RED}####${NOFORMAT}"
    exit 1
}

parse_params() {
    # default values of variables set from params
    unfreeze=0

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        --no-color) NO_COLOR=1 ;;
        -u | --unfreeze) unfreeze=1 ;; 
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    return 0
}

parse_params "$@"
setup_colors

# Script logic
if [ "$EUID" -ne 0 ]; then
    die "${RED}####${NOFORMAT} Please run as root ${RED}####${NOFORMAT}"
fi

# Check for curl
if [ ! -x "$(which curl)" ]; then
    die "${RED}####${NOFORMAT} Please install curl ${RED}####${NOFORMAT}"
fi

. ./files/functions.sh

if [ "$unfreeze" -eq 0 ]; then
    # Freeze if variable equal 0
    msg "${YELLOW}####${NOFORMAT} Starting deep freeze in 5 seconds ${YELLOW}####${NOFORMAT}"
    msg "${YELLOW}####${NOFORMAT} Quit now (CTRL-C) if you didn't backup important files ${YELLOW}####${NOFORMAT}"
    # Countdown to 5 before start
    i=5 && while [ $i -gt 0 ]; do sleep 1; i=$(($i-1)); printf "$i "; done && echo

    # Backup of important grub file
    cp /etc/default/grub /etc/default/grub.lethe.bkp`date '+%s'`

    # Changing grub entries
    msg "${YELLOW}####${NOFORMAT} Changing grub entries ${YELLOW}####${NOFORMAT}"
    sed -i '0,/#GRUB_TIMEOUT_STYLE=.*/s//GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
    sed -i '0,/GRUB_TIMEOUT_STYLE=.*/s//GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
    sed -i '0,/#GRUB_CMDLINE_LINUX_DEFAULT=.*/s//GRUB_CMDLINE_LINUX_DEFAULT=\"splash acpi=force\"/' /etc/default/grub
    sed -i '0,/GRUB_CMDLINE_LINUX_DEFAULT=.*/s//GRUB_CMDLINE_LINUX_DEFAULT=\"splash acpi=force\"/' /etc/default/grub
    sed -i '0,/#GRUB_TIMEOUT=.*/s//GRUB_TIMEOUT=2/' /etc/default/grub
    sed -i '0,/GRUB_TIMEOUT=.*/s//GRUB_TIMEOUT=2/' /etc/default/grub
    sed -i '0,/GRUB_DISTRIBUTOR=.*/s//GRUB_DISTRIBUTOR="Persistent (not Lethe-freezed) \`lsb_release -i -s 2> \/dev\/null \|\| echo Debian\`"/' /etc/default/grub
    msg "${GREEN}####${NOFORMAT} Changed grub entries ${GREEN}####${NOFORMAT}"

    msg "${YELLOW}####${NOFORMAT} Updating grub ${YELLOW}####${NOFORMAT}"
    update-grub
    msg "${GREEN}####${NOFORMAT} Updated grub ${GREEN}####${NOFORMAT}"

    msg "${YELLOW}####${NOFORMAT} Installing lethe ${YELLOW}####${NOFORMAT}"
    
    msg "${YELLOW}####${NOFORMAT} Downloading lethe ${YELLOW}####${NOFORMAT}"
    ( curl --fail --silent --show-error -o /tmp/lethe.deb https://raw.githubusercontent.com/TheArqsz/deep-freezer/main/files/lethe_0.34_all.deb && \
    msg "${GREEN}####${NOFORMAT} Downloaded lethe ${GREEN}####${NOFORMAT}" ) || \
    die "Didn't download lethe properly"

    # Create this file according to answer from https://askubuntu.com/a/1083416/1187460
    cat <<\EOF | tee /usr/lib/grub/update-grub_lib
# stub for new grub-mkconfig_lib
# Copyright (C) 2007,2008  Free Software Foundation, Inc.
#
# GRUB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GRUB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GRUB.  If not, see <http://www.gnu.org/licenses/>.

prefix="/usr"
exec_prefix="${prefix}"
datarootdir="${prefix}/share"

. "${datarootdir}/grub/grub-mkconfig_lib"

grub_warn "update-grub_lib is deprecated, use grub-mkconfig_lib instead"
EOF
    chmod a+rwx /usr/lib/grub/update-grub_lib
    apt-get install -y --ignore-missing /tmp/lethe.deb 2>/var/log/deepfreeze.error.log
    find /var/crash/ -iname "lethe.*" -exec rm -rf {} \; 2>/var/log/deepfreeze.error.log
    rm /tmp/lethe.deb
    msg "${GREEN}####${NOFORMAT} Installed lethe ${GREEN}####${NOFORMAT}"

    msg "${YELLOW}####${NOFORMAT} Final updates ${YELLOW}####${NOFORMAT}"
    update_boot
    sed -i 's/source ${rootmnt}\/etc\/lethe\/lethe.conf/. ${rootmnt}\/etc\/lethe\/lethe.conf/g' /etc/initramfs-tools/scripts/local-bottom/lethe
    sed -i "s/aufs=tmpfs$/aufs=tmpfs apparmor=0/" /etc/lethe/09_lethe /etc/grub.d/09_lethe
    update-initramfs -u -k all
    update-grub

    distro=`lsb_release -i -s 2> /dev/null || echo Debian`

    msg "${GREEN}Finished deep freeze${NOFORMAT}"
else
    # Unfreeze if variable equal 1
    grub_bckp="`ls -t1 /etc/default/ | grep "grub.lethe.bkp" | head -n1`" || true
    if [ -z "$grub_bckp" ]; then
        msg "${YELLOW}####${NOFORMAT} No previous backup of grub - ignoring grub entries ${YELLOW}####${NOFORMAT}"
    else
        cp /etc/default/grub /etc/default/unfreeze-grub.tmp
        mv "/etc/default/$grub_bckp" /etc/default/grub 
        update-grub
    fi
    [ -z "/etc/grub.d/09_lethe" ] && rm /etc/grub.d/09_lethe
    update_postrm
    apt-get purge -y --ignore-missing lethe 2>/var/log/deepfreeze.error.log || die "Error during uninstalling"
    msg "${GREEN}Finished unfreeze - reboot in 5 seconds (CTR-C to interrupt it) ${NOFORMAT}"
    i=5 && while [ $i -gt 0 ]; do sleep 1; i=$(($i-1)); printf "$i "; done && reboot

fi
