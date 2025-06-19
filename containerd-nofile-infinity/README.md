# Configure Containerd NOFILE Limit

This guide outlines the steps to configure the `LimitNOFILE` setting for the Containerd service on GKE nodes. This is typically used to increase the maximum number of open file descriptors allowed for Containerd, which can be beneficial for high-concurrency workloads or specific applications that require a large number of open files.

## Instructions

1.  Deploy the daemonset in `nofile-infinity-daemonset.yaml`. This DaemonSet runs a privileged container that modifies the `containerd.service` systemd unit on each node to set `LimitNOFILE=infinity` and then restarts the Containerd service.

    ```bash
    kubectl apply -f nofile-infinity-daemonset.yaml
    ```

## Note
**This DaemonSet is specifically allowlisted for GKE Autopilot clusters.** Attempting to deploy privileged DaemonSets that modify the underlying host OS on Autopilot may lead to unexpected behavior, stability issues, or may be prevented by Autopilot's security policies. If you need to make any necessary change, please ask your Google Cloud sales representative to reach to the GKE Autopilot team.
