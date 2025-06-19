# Configure Containerd NOFILE Limit

This guide outlines the steps to configure the `LimitNOFILE` setting for the containerd service on GKE nodes. This is typically used to increase the maximum number of open file descriptors allowed for containerd, which can be beneficial for high-concurrency workloads or specific applications that require a large number of open files. Since containerd 2.0 the `LimitNOFILE` has been removed - see containerd/containerd#8924 for more details.

## Prerequiste for GKE Autopilot Clusters:
Deploy the `AllowListSynchronizer` resource in `containerd-nofile-infinity-allowlist.yaml`. This resource updates [Autopilot's security policies](https://cloud.google.com/kubernetes-engine/docs/how-to/run-autopilot-partner-workloads#about-allowlistsynchronizer) to run the privileged daemonset.
    
```bash
kubectl apply -f containerd-nofile-infinity-allowlist.yaml
```  

## Instructions

1.  Deploy the daemonset in `containerd-nofile-infinity.yaml`. This DaemonSet runs a privileged container that modifies the `containerd.service` systemd unit on each node to set `LimitNOFILE=infinity` and then restarts the Containerd service.

    ```bash
    kubectl apply -f containerd-nofile-infinity.yaml
    ```

## Note
**This DaemonSet is specifically allowlisted for GKE Autopilot clusters.** Attempting to deploy privileged DaemonSets that modify the underlying host OS on Autopilot may lead to unexpected behavior, stability issues, or prevented by Autopilot's security policies. If you need to make any necessary change, please ask your Google Cloud sales representative to reach to the GKE Autopilot team.
