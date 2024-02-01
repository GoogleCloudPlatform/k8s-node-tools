# Configure Containerd HTTP/S proxy

This guide outlines the steps to configure the HTTP/S proxy for Containerd within a Kubernetes environment, specifically tailored for GKE Autopilot clusters.

## Instruction

1. Create a ConfigMap named containerd-proxy-configmap that includes the values for HTTP_PROXY, HTTPS_PROXY, and NO_PROXY (optional). These values are used as environment variables to configure the proxy settings for the Containerd service. A sample ConfigMap configuration is provided in sample_configmap.yaml. Please modify this sample with your proxy settings before applying it to your cluster.
2. Deploy the daemonset in configure_http_proxy.yaml. As it has been specifically allowlisted for GKE Autopilot, the manifest shouldn’t be changed to make sure it can be deployed successfully in GKE Autopilot clusters.

## Note
Any update on the configure_http_proxy.yaml will break the allowlist for GKE
Autopilot. If you need to make any necessary change, please contact GKE
Autopilot team to re-allowlist the daemonset.
