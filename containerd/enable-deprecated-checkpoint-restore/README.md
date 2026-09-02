# Re-enable containerd Checkpoint Restore (CreateContainer)

Starting with containerd 2.2.7 and 2.3.4, checkpoint restore via CRI `CreateContainer` is deprecated and disabled by default, and is removed entirely in containerd 2.4+. For details, see the announcement on the [kubernetes-dev mailing list](https://groups.google.com/a/kubernetes.io/g/dev/c/O420PQSbTn8).

Standard Kubernetes workloads are unaffected. Workloads that restore container checkpoints (which requires `criu` on the node) fail during container creation with:

```
rpc error: code = Unknown desc = checkpoint restore via CreateContainer is disabled by configuration
```

This DaemonSet re-enables the deprecated feature by setting `enable_experimental_restore_via_create = true` in `/etc/containerd/config.toml` and restarting containerd.

## Caution

The containerd project cautions that if restore via `CreateContainer` is enabled, only trusted users should be granted permission to create pods and only trusted values should be specified in the `image:` field of a pod.

## Prerequisites & Compatibility

* **GKE Standard only:** This DaemonSet requires privileged host access to modify `/etc/containerd/config.toml` and restart containerd. It is not supported on GKE Autopilot.
* **containerd restart:** Deploying this workload restarts the containerd service on each targeted node.

## Usage

Apply the DaemonSet to your cluster:

```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-node-tools/master/containerd/enable-deprecated-checkpoint-restore/enable-deprecated-checkpoint-restore.yaml
```

Or apply the local file:

```bash
kubectl apply -f enable-deprecated-checkpoint-restore.yaml
```

## Verification

To verify that the deprecation warning is registered when a container creation from a checkpoint image is attempted, run the following command on a node:

```bash
sudo ctr --namespace k8s.io deprecations list
```

Restored containers also carry runtime annotations in `crictl`:

```bash
sudo crictl ps -a -o json | jq -r '
  [ .containers[]?
    | select(.annotations.restored == "true")
    | "container=\(.id[0:12]) (pod=\(.labels["io.kubernetes.pod.namespace"] // "unknown")/\(.labels["io.kubernetes.pod.name"] // "unknown")), name=\(.metadata.name // "unknown"), checkpointedAt=\(.annotations.checkpointedAt // "unknown"), checkpointImage=\(.annotations.checkpointImage // "unknown")"
  ] | .[]'
```

## Removal

To remove the DaemonSet:

```bash
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-node-tools/master/containerd/enable-deprecated-checkpoint-restore/enable-deprecated-checkpoint-restore.yaml
```

Note that removing the DaemonSet does not revert the configuration in `/etc/containerd/config.toml` until the node is recreated or the configuration field is manually removed.
