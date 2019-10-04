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

set -xeou pipefail

# Enable SMT and reboot if SMT is currently disabled.
enable_smt() {
  if [[ ! $(grep " nosmt " /proc/cmdline) ]]; then
    echo "'nosmt' is not present on the kernel command line. Nothing to do."
    return
  fi
  echo "Attempting to remove 'nosmt' on the kernel command line."
  if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root."
    return 1
  fi

  dir="$(mktemp -d)"
  mount /dev/sda12 "${dir}"
  sed -i -e "s| nosmt||g" "${dir}/efi/boot/grub.cfg"
  umount "${dir}"
  rmdir "${dir}"
  echo "Rebooting."
  reboot
}

enable_smt