# Migrating to Containerd

Find information about running Containerd nodes on GKE [here](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd).

The sample script `find-nodepools-to-migrate.sh` iterates over all node pools across available projects, and for each node pool outputs the suggestion on whether the node pool should be migrated to Containerd. This script also outputs the node pool version and suggested migration command as listed in the [updating your node images](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#updating-image-type) document. Make sure that you review the [known issues](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd#known_issues) for a node pool version before migration.
