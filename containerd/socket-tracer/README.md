# Tracing containerd Socket Connections

The `containerd-socket-tracer.yaml` is a DaemonSet that monitors and logs
connections made to the `containerd` socket. This is particularly useful for
identifying which containers are interacting with the container runtime
directly.

Before deploying, please review the
[important considerations](#important-considerations)
regarding potential performance impact and system conflicts.

### How It Works

This tool leverages [eBPF](https://ebpf.io/) to trace system calls. It watches
for any process that attempts to open a connection to the `containerd` socket.
Once a connection is detected, the tracer identifies the PID and queries the
node's [CRI](https://kubernetes.io/docs/concepts/architecture/cri/) to resolve
the corresponding Pod and container details.

## Example Use Case: Identifying Deprecated API Clients

A practical application for this tracer is to identify applications that are
still using the
[deprecated CRI v1alpha2 API](https://github.com/containerd/containerd/blob/v2.1.2/RELEASES.md?plain=1#L167).
As `containerd` moves towards newer API versions, it's crucial to find and update
any clients using outdated versions.

The following sections describe two methods for finding these clients: a manual
approach using SSH and an automated approach using a companion workload.

### Method 1: Manual Correlation via SSH

While the tracer is running, it will generate log entries for every container
that establishes a socket connection.

**Example Log Output:**

```
time="2025-06-16T18:19:10Z" msg="eBPF tracepoint for containerd socket connections started" node="gke-cluster-default-pool-1e092676-x8m9"
time="2025-06-16T18:19:30Z" msg="containerd socket connection opened" node="gke-cluster-default-pool-1e092676-x8m9" pod="default/cri-v1alpha2-api-client-dmghs" container="deployment-container-1" comm="v1alpha2_client"
```

If your version of `containerd` includes the
[deprecation service](https://samuel.karp.dev/blog/2024/01/deprecation-warnings-in-containerd-getting-ready-for-2.0/),
you can correlate the timestamp from the tracer's log with the `lastOccurrence`
of the deprecated API call. This allows you to pinpoint the exact application
making the call.

**Correlating with `containerd` Deprecation Warnings:**

```sh
$ ctr deprecations list --format json | jq '.[] | select(.id == "io.containerd.deprecation/cri-api-v1alpha2")'
{
  "id": "io.containerd.deprecation/cri-api-v1alpha2",
  "message": "CRI API v1alpha2 is deprecated since containerd v1.7 and removed in containerd v2.0. Use CRI API v1 instead.",
  "lastOccurrence": "2025-06-16T18:21:30.959558222Z"
}
```

### Method 2: Automated Correlation with a Reporter Workload

To simplify this process, a second workload,
`cri-v1alpha2-api-deprecation-reporter.yaml`, is provided. This DaemonSet
periodically logs the occurrence of the last CRI v1alpha2 API call.

**Example Log Output:**

```
time="2025-06-16T18:22:19Z" msg="checking for CRI v1alpha2 API deprecation warnings" node="gke-cluster-default-pool-1e092676-x8m9"
time="2025-06-16T18:22:19Z" msg="found CRI v1alpha2 API deprecation warning" node="gke-cluster-default-pool-1e092676-x8m9" lastOccurrence="2025-06-16T18:21:30.959558222Z"
```

### Putting It All Together: Finding the Client

With both DaemonSets deployed and running, you can find the deprecated API client by correlating the logs from both tools.

In one terminal, stream the logs from the reporter to watch for deprecation events:

```sh
$ kubectl logs -f -l name=cri-v1alpha2-api-deprecation-reporter
```

In a second terminal, stream the logs from the tracer to watch for new connections:

```sh
$ kubectl logs -f -l name=containerd-socket-tracer
```

**Wait and Compare:** When a `lastOccurrence` timestamp appears in the reporter's log, look for a "containerd socket connection opened" event in the tracer's log that occurred on the **same node** at nearly the **exact same time**.

Alternatively, if your cluster is configured to send logs to a centralized platform, you can run a single query to see the aggregated logs from all nodes at once. This is the recommended approach for analyzing historical data and correlating events across your entire cluster.

For example, users on Google Kubernetes Engine (GKE) can use the following query in Cloud Logging to view the output from both workloads:

```
resource.type="k8s_container"
(
  labels."k8s-pod/name"="containerd-socket-tracer"
  OR
  labels."k8s-pod/name"="cri-v1alpha2-api-deprecation-reporter"
)
```

This correlation between the two log events pinpoints the exact pod and container that is responsible for the deprecated API call.

### Filtering Commands (`comm`)

To reduce noise, the underlying `bpftrace` script is configured to ignore a
default set of common, node-level commands (like `kubelet` and `containerd`
itself). The primary focus is on identifying connections from other,
containerized applications.

You can customize this behavior by modifying the `bpftrace`
[filter](https://github.com/bpftrace/bpftrace/blob/v0.23.5/man/adoc/bpftrace.adoc#filterspredicates)
to include or exclude other commands as needed.

## Important Considerations

Please review the following disclaimers before deploying this workload.

### Production Use

Always test this tool in a dedicated test environment before deploying to
production. For production rollouts, use exposure control by deploying to a
small subset of nodes first to monitor for any adverse effects.

This tool is intended for temporary, targeted debugging, not for prolonged
execution. Its main purpose is to help identify workloads violating containerd
deprecations when other detection methods have been unsuccessful.

### CPU Overhead

Enabling this tracer may increase the CPU load on your nodes. This is especially
true if the `comm` filter is not restrictive enough and there is a high volume
of socket connections.

### Potential eBPF Conflicts

Running this tracer on nodes where other eBPF-based tools are already active may
lead to unexpected behavior or conflicts.

## Installation

To deploy the tracer to your cluster, apply the `containerd-socket-tracer.yaml`
manifest using `kubectl`.

```sh
$ kubectl apply -f containerd-socket-tracer.yaml
```

And to deploy the optional API reporter:

```sh
$ kubectl apply -f cri-v1alpha2-api-deprecation-reporter.yaml
```

### GKE Autopilot Users

GKE Autopilot clusters enforce security policies that prevent workloads
requiring privileged access from running by default. To deploy the
`containerd-socket-tracer` and its companion
`cri-v1alpha2-api-deprecation-reporter`, you must first install the
corresponding `AllowlistSynchronizer` resources in your cluster.

These synchronizers enable the workloads to run on Autopilot nodes by matching
them with a `WorkloadAllowlist`.

To install the allowlists, apply the following manifests:

```sh
$ kubectl apply -f containerd-socket-tracer-allowlist.yaml
$ kubectl apply -f cri-v1alpha2-api-deprecation-reporter-allowlist.yaml
```

After applying these manifests and allowing a few moments for the allowlists to
synchronize, you can deploy the `containerd-socket-tracer` and
`cri-v1alpha2-api-deprecation-reporter` DaemonSets as described above.
