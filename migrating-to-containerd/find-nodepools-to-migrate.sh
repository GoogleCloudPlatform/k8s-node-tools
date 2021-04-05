#!/bin/bash

# [START gke_node_find_non_containerd_nodepools]
for project in  $(gcloud projects list --format="value(projectId)")
do
  echo "ProjectId:  $project"
  for clusters in $( \
    gcloud container clusters list \
      --project $project \
      --format="csv[no-heading](name,location,autopilot.enabled)")
  do
    IFS=',' read -r -a clustersArray <<< "$clusters"
    cluster_name="${clustersArray[0]}"
    cluster_zone="${clustersArray[1]}"
    cluster_isAutopilot="${clustersArray[2]}"

    if [ "$cluster_isAutopilot" = "True" ]; then
      echo "  Cluster: $cluster_name (autopilot) (zone: $cluster_zone)"
      echo "    Autopilot clusters are running Containerd."
    else
      echo "  Cluster: $cluster_name (zone: $cluster_zone)"
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

        suggestedImageType="COS_CONTAINERD"

        if [ "$nodepool_imageType" = "UBUNTU" ]; then
          suggestedImageType="UBUNTU_CONTAINERD"
        fi

        tab=$'\n      ';
        nodepool_message="$tab Please update the nodepool to use Containerd."
        nodepool_message+="$tab Make sure to consult with the list of known issues https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#known_issues."
        nodepool_message+="$tab Run the following command to upgrade:"
        nodepool_message+="$tab "
        nodepool_message+="$tab gcloud container clusters upgrade '$cluster_name' --project '$project' --zone '$cluster_zone' --image-type '$suggestedImageType' --node-pool '$nodepool_name'"
        nodepool_message+="$tab "

        # see https://cloud.google.com/kubernetes-engine/docs/concepts/node-images
        if [ "$nodepool_imageType" = "COS_CONTAINERD" ] || [ "$nodepool_imageType" = "UBUNTU_CONTAINERD" ]; then
          nodepool_message="$tab Nodepool is using Containerd already"
        elif [ "$nodepool_imageType" = "WINDOWS_LTSC" ] || [ "$nodepool_imageType" = "WINDOWS_SAC" ]; then
          nodepool_message="$tab Containerd is not currently available for Windows nodepools"
        elif [ "$nodepool_minorVersion" \< "1.14" ]; then
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
#  Cluster: another-test-cluster (zone: us-central1-c)
#    Nodepool: default-pool, version: 1.20.4-gke.400 (1.20), image: COS_CONTAINERD
#
#      Nodepool is using Containerd already
#
# [END gke_node_find_non_containerd_nodepools]