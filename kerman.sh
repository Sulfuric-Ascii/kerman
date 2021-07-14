#    Copyright (C) 2021 Jennifer Hooks
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/bin/sh -e

usage() { printf %s "\
kerman - kernel manager

-a [version] initalize a new kernel(will overwrite)
-l list all installed kernels
-r [version] purge a kernel
"
exit 1
}

die() { 
    printf 'error: %s.\n' "$1" >&2
    exit 1
}

list_kernels() {
    find -L "/boot" -name "*vmlinuz*" | sed 's/.*z-//'
}

pick_kernel() {
    list_kernels
    printf "Type name of kernel: "
    read -r TEST_VAR
    printf "%s\n" "$TEST_VAR"
}

# Need some way to skip generating a boot entry if overwriting
name_kernel() {
    [ -e "/boot/System.map" ] || die "System.map not found or already renamed"
    [ -e "/boot/vmlinuz" ] || die "vmlinuz not found or already renamed"
    mv "/boot/System.map" "/boot/System.map-$1"
    mv "/boot/vmlinuz" "/boot/vmlinuz-$1"
}

gen_boot() {
    ROOT_PARTUUID="$(lsblk -ro +PARTUUID | grep -w '/' | sed 's/.*\/ //')"
    efibootmgr --disk /dev/sda --part 1 --create --label "Linux-$1" \
    --loader "/vmlinuz-$1" --unicode "root=PARTUUID=$ROOT_PARTUUID rw" \
    --quiet || die "Couldn't create boot entry"
}

remove_boot() {
    ENTRY="$(efibootmgr | grep "Linux-$1" | sed -e 's/Boot//' -e 's/\*.*//')"
    # efibootmgr selects first boot entry if given an empty var
    [ -z "$ENTRY" ] && die "Boot entry Linux-$1 not found"
    efibootmgr -b "$ENTRY" -Bq
}

remove_modules() {
    [ -e "/usr/lib/modules/$1" ] && rm -rf "/usr/lib/modules/$1"
}

remove_kernel() {
    [ -e "/boot/System.map-$1" ] || die "System.map-$1 not found"
    [ -e "/boot/vmlinuz-$1" ] || die "vmlinuz-$1 not found"
    rm -f "/boot/System.map-$1"
    rm -f "/boot/vmlinuz-$1"
}

purge_kernel() {
    remove_boot    "$1"
    remove_modules "$1"
    remove_kernel  "$1"
}

init_kernel() {
    name_kernel "$1"
    gen_boot "$1"
}

main() {
    [ "$(id -u)" = 0 ] || die "Script needs to run as root"

    case "$1" in
        "-a") init_kernel "$2"  ;;
        "-l") list_kernels      ;;
        "-r") purge_kernel "$2" ;;
        "-t") pick_kernel       ;;
          * ) usage             ;;
    esac
}

main "$@"
