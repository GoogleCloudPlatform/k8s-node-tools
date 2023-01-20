#!/bin/sh

# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Example: `./manual_node_upgrade.sh <cluster> <region>`
#

CLUSTER_NAME=$1
REGION=$2

# fetch current control plane version
CLUSTER_VERSION=$(gcloud container clusters describe \
  $CLUSTER_NAME  --format="value(currentMasterVersion)" \
  --region=$REGION)

# list node pools with version not matching control plane
for np in $(gcloud container node-pools list \
  --format="value(name)" --filter="version!=$CLUSTER_VERSION" \
  --cluster $CLUSTER_NAME --region=$REGION); do
  gcloud container clusters upgrade $CLUSTER_NAME --node-pool $np \
    --region=$REGION --quiet;
done