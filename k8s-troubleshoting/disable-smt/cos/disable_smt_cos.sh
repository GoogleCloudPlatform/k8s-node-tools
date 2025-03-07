#!/bin/bash
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# Exits if the system uses secure boot.
function check_not_secure_boot() {
  if [[ ! -d "/sys/firmware/efi" ]]; then
    return
  fi

  efi="$(mktemp -d)"
  mount -t efivarfs none "${efi}"

  # Read the secure boot variable.
  secure_boot="$(hexdump -v -e '/1 "%02X "' ${efi}/SecureBoot-*)"

  # Clean up
  umount "${efi}"
  rmdir "${efi}"

  # https://wiki.archlinux.org/index.php/Secure_Boot
  if [[ "${secure_boot}" == "06 00 00 00 01 " ]]; then
    echo "Secure Boot is enabled. Boot options cannot be changed."
    exit 1
  fi
}

# Disable SMT and reboot if SMT is currently enabled
function disable_smt() {
  if grep " nosmt " /proc/cmdline > /dev/null; then
    echo "'nosmt' already present on the kernel command line. Nothing to do."
    return
  fi
  echo "Attempting to set 'nosmt' on the kernel command line."
  if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root."
    return 1
  fi
  check_not_secure_boot

  dir="$(mktemp -d)"
  mount /dev/sda12 "${dir}"
  sed -i -e "s|cros_efi|cros_efi nosmt|g" "${dir}/efi/boot/grub.cfg"
  umount "${dir}"
  rmdir "${dir}"
  echo "Rebooting."
  reboot
}

disable_smt
