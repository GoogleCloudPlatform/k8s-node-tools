#!/bin/bash

# [START gke_node_find_non_containerd_nodepools]
for project in  $(gcloud projects list --format="value(projectId)" --filter="- projectId:sys-*")
do
  for clusters in $( \
    gcloud container clusters list \
      --project $project \
      --format="csv[no-heading](name,location,autopilot.enabled,currentMasterVersion,autoscaling.enableNodeAutoprovisioning,autoscaling.autoprovisioningNodePoolDefaults.imageType)")
  do
    printf '=%.0s' $(seq 1 $(tput cols))    
    echo ""
    echo "ProjectId:  $project"

    IFS=',' read -r -a clustersArray <<< "$clusters"
    cluster_name="${clustersArray[0]}"
    cluster_zone="${clustersArray[1]}"
    cluster_isAutopilot="${clustersArray[2]}"
    cluster_version="${clustersArray[3]}"
    cluster_minorVersion=${cluster_version:0:4}
    cluster_autoprovisioning="${clustersArray[4]}"
    cluster_autoprovisioningImageType="${clustersArray[5]}"

    if [ "$cluster_isAutopilot" = "True" ]; then
      echo "  Cluster: $cluster_name (autopilot) (zone: $cluster_zone)"
      echo "    Autopilot clusters are running Containerd."
    else
      echo "  Cluster: $cluster_name (zone: $cluster_zone)"

      if [ "$cluster_autoprovisioning" = "True" ]; then
        if [ "$cluster_minorVersion"  \< "1.20" ]; then
          echo "    Node autoprovisioning is enabled, and new node pools will have image type 'COS'."
          echo "    This settings is not configurable on the current version of a cluster."
          echo "    Please upgrade you cluster and configure the default node autoprovisioning image type."
          echo "    "
        else
          if [ "$cluster_autoprovisioningImageType" = "COS" ]; then
            echo "    Node autoprovisioning is configured to create new node pools of type 'COS'."
            echo "    Run the following command to update:"
            echo "    gcloud container clusters update '$cluster_name' --project '$project' --zone '$cluster_zone' --enable-autoprovisioning --autoprovisioning-image-type='COS_CONTAINERD'"
            echo "    "
          fi

          if [ "$cluster_autoprovisioningImageType" = "UBUNTU" ]; then
            echo "    Node autoprovisioning is configured to create new node pools of type 'UBUNTU'."
            echo "    Run the following command to update:"
            echo "    gcloud container clusters update '$cluster_name' --project '$project' --zone '$cluster_zone' --enable-autoprovisioning --autoprovisioning-image-type='UBUNTU_CONTAINERD'"
            echo "    "
          fi
        fi
      fi

      for nodepools in $( \
        gcloud container node-pools list \
          --project $project \
          --cluster $cluster_name \
          --zone $cluster_zone \
          --format="csv[no-heading](name,version,config.imageType)")
      do
        IFS=',' read -r -a nodepoolsArray <<< "$nodepools"
        nodepool_name="${nodepoolsArray[0]}"
        nodepool_version="${nodepoolsArray[1]}"
        nodepool_imageType="${nodepoolsArray[2]}"

        nodepool_minorVersion=${nodepool_version:0:4}

        echo "    Nodepool: $nodepool_name, version: $nodepool_version ($nodepool_minorVersion), image: $nodepool_imageType"

        minorVersionWithRev="${nodepool_version/-gke./.}"
        linuxGkeMinVersion="1.14"
        windowsGkeMinVersion="1.21.1.2200"

        suggestedImageType="COS_CONTAINERD"

        if [ "$nodepool_imageType" = "UBUNTU" ]; then
          suggestedImageType="UBUNTU_CONTAINERD"
        elif [ "$nodepool_imageType" = "WINDOWS_LTSC" ]; then
          suggestedImageType="WINDOWS_LTSC_CONTAINERD"
        elif [ "$nodepool_imageType" = "WINDOWS_SAC" ]; then
          suggestedImageType="WINDOWS_SAC_CONTAINERD"
        fi

        tab=$'\n      ';
        nodepool_message="$tab Please update the nodepool to use Containerd."
        nodepool_message+="$tab Make sure to consult with the list of known issues https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#known_issues."
        nodepool_message+="$tab Run the following command to upgrade:"
        nodepool_message+="$tab "
        nodepool_message+="$tab gcloud container clusters upgrade '$cluster_name' --project '$project' --zone '$cluster_zone' --image-type '$suggestedImageType' --node-pool '$nodepool_name'"
        nodepool_message+="$tab "

        # see https://cloud.google.com/kubernetes-engine/docs/concepts/node-images
        if [ "$nodepool_imageType" = "COS_CONTAINERD" ] || [ "$nodepool_imageType" = "UBUNTU_CONTAINERD" ] ||
           [ "$nodepool_imageType" = "WINDOWS_LTSC_CONTAINERD" ] || [ "$nodepool_imageType" = "WINDOWS_SAC_CONTAINERD" ]; then
          nodepool_message="$tab Nodepool is using Containerd already"
        elif ( [ "$nodepool_imageType" = "WINDOWS_LTSC" ] || [ "$nodepool_imageType" = "WINDOWS_SAC" ] ) &&
               !( [ "$(printf '%s\n' "$windowsGkeMinVersion" "$minorVersionWithRev" | sort -V | head -n1)" = "$windowsGkeMinVersion" ] ); then
          nodepool_message="$tab Upgrade nodepool to the version that supports Containerd for Windows"
        elif !( [ "$(printf '%s\n' "$linuxGkeMinVersion" "$minorVersionWithRev" | sort -V | head -n1)" = "$linuxGkeMinVersion" ] ); then
          nodepool_message="$tab Upgrade nodepool to the version that supports Containerd"
        fi
        echo "$nodepool_message"
      done
    fi # not autopilot
  done
done

# Sample output:
#
# ProjectId:  my-project-id
#  Cluster: autopilot-cluster-1 (autopilot) (zone: us-central1)
#    Autopilot clusters are running Containerd.
#  Cluster: cluster-1 (zone: us-central1-c)
#    Nodepool: default-pool, version: 1.18.12-gke.1210 (1.18), image: COS
#
#       Please update the nodepool to use Containerd.
#       Make sure to consult with the list of known issues https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#known_issues.
#       Run the following command to upgrade:
#
#       gcloud container clusters upgrade 'cluster-1' --project 'my-project-id' --zone 'us-central1-c' --image-type 'COS_CONTAINERD' --node-pool 'default-pool'
#
#    Nodepool: pool-1, version: 1.18.12-gke.1210 (1.18), image: COS
#
#       Please update the nodepool to use Containerd.
#       Make sure to consult with the list of known issues https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#known_issues.
#       Run the following command to upgrade:
#
#       gcloud container clusters upgrade 'cluster-1' --project 'my-project-id' --zone 'us-central1-c' --image-type 'COS_CONTAINERD' --node-pool 'pool-1'
#
#    Nodepool: winpool, version: 1.18.12-gke.1210 (1.18), image: WINDOWS_SAC
#
#       Upgrade nodepool to the version that supports Containerd for Windows
#
#  Cluster: another-test-cluster (zone: us-central1-c)
#    Nodepool: default-pool, version: 1.20.4-gke.400 (1.20), image: COS_CONTAINERD
#
#      Nodepool is using Containerd already
#
# [END gke_node_find_non_containerd_nodepools]
#
