# Configure Containerd HTTP/S proxy

This guide outlines the steps to configure a HTTP/S proxy for Containerd on GKE nodes, including Autopilot mode clusters. Typical use cases include access of external image repositories for container pulls.

## Instructions

1. Create a ConfigMap named `containerd-proxy-configmap` that includes the values for `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` (optional). These values are used as environment variables to configure the proxy settings for the Containerd service. A sample ConfigMap configuration is provided in `sample_configmap.yaml`. Please modify this sample with your proxy settings before applying it to your cluster.


2. Deploy the daemonset in `configure_http_proxy.yaml`. As it has been specifically allowlisted for GKE Autopilot, this **manifest in this repo cannot be changed if you are deploying to GKE Autopilot mode clusters**.


## Note
**Any update on the `configure_http_proxy.yaml` will break the allowlist for GKE Autopilot**. If you need to make any necessary change, please ask your Google Cloud sales representative to reach to the GKE Autopilot team.
