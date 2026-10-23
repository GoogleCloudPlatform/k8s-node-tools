# Container-Optimized OS (COS) Live CA-Certificate Mitigation

This directory provides live mitigation tools to distrust the compromised eMudhra (`emSign`) root CAs and the cross-signing `AAA Certificate Services` (`Comodo_AAA_Services_root.crt`) root CA on running **Container-Optimized OS (COS)** instances and **Google Kubernetes Engine (GKE)** Standard nodes before upgrading to patched OS images.

## What This Mitigation Does

1. **System CA Store (`/etc/ca-certificates.conf` & `/etc/ssl/certs`)**:
   - Deselects all `mozilla/emSign_*.crt` roots and `mozilla/Comodo_AAA_Services_root.crt` in `/etc/ca-certificates.conf` and runs `update-ca-certificates --fresh`.
   - Mitigates host OpenSSL/C/C++ consumers (`curl`, `wget`, `git`, `oslogin`, `systemd`, `chrony`), host Python (`certifi`, `urllib3`, `requests`, `cloud-init`), and Go `crypto/x509` CLIs (`kubectl`, `crictl`, `ctr`, `docker`).
2. **Read-Only `/usr` Trust Stores (`dm-verity`)**:
   - Masks `/usr/share/chromeos-ca-certificates/Comodo_AAA_Services_root.pem` via a bind mount from `/dev/null` (mitigating `update_engine`, `libbrillo`, and `crash_sender`).
   - Bind-mounts the regenerated `/etc/ssl/certs/ca-certificates.crt` over `/usr/share/grpc/roots.pem` if present.
3. **Built-In Container Utilities (`toolbox` & `cos-extensions`)**:
   - Updates `TOOLBOX_DOCKER_TAG="v20261020"` in `/etc/default/toolbox`.
   - Wraps `/usr/bin/cos-extensions` via `/run/cos-mitigation` so `cos-extensions install gpu` defaults to `gcr.io/cos-cloud/cos-gpu-installer:v2.7.11`.
   - On GKE GPU nodes where `docker.io/library/cos-nvidia-installer:fixed` is preloaded in `containerd` (`k8s.io` namespace), pulls `gcr.io/cos-cloud/cos-gpu-installer:v2.7.11` and retags `docker.io/library/cos-nvidia-installer:fixed` and `gcr.io/cos-cloud/cos-gpu-installer:fixed`.
4. **Active Host Daemons**:
   - Restarts active host services (`containerd`, `docker`, `kubelet`, `fluent-bit`, `update-engine`, `node-problem-detector`, `gke-node-problem-detector`, `google-guest-agent*`, `google-osconfig-agent`, `device_policy_manager`) so long-running Go and C/C++ processes reload `/etc/ssl/certs/ca-certificates.crt` without disrupting running pods.

---

## 1. GKE Standard Nodes (`COS_CONTAINERD`)

Deploy the `cos-ca-cert-mitigator` DaemonSet to automatically apply the mitigation across all existing and newly autoscaled COS nodes in a GKE Standard cluster.

### Prerequisites & Compatibility
* **GKE Standard only:** This DaemonSet requires privileged host access (`hostPID: true`, `privileged: true`) to update host trust stores and restart node services.
* **No Node Reboot or Pod Eviction:** Restarting `containerd` and `kubelet` reloads the host trust store in-place while running pods remain managed by their `containerd-shim` processes.

### Usage

Apply the DaemonSet to your cluster:

```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-node-tools/master/cos-ca-cert-mitigation/gke/cos-ca-cert-mitigation.yaml
```

Or apply the local file:

```bash
kubectl apply -f gke/cos-ca-cert-mitigation.yaml
```

Monitor the rollout status and inspect the init container logs:

```bash
kubectl -n kube-system rollout status daemonset/cos-ca-cert-mitigator
kubectl -n kube-system logs -l k8s-app=cos-ca-cert-mitigator -c apply-cos-ca-cert-mitigation
```

### Removal

Once your node pools have been upgraded to a patched COS image release, remove the DaemonSet:

```bash
kubectl delete -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-node-tools/master/cos-ca-cert-mitigation/gke/cos-ca-cert-mitigation.yaml
```

---

## 2. Standalone Container-Optimized OS (COS) GCE VMs

On standalone COS GCE VMs, copy `cos/mitigate_cos_ca_certs.sh` to the instance and execute it as `root`:

```bash
sudo bash mitigate_cos_ca_certs.sh
```

> **Note:** Because `/tmp` and `/home` on COS are mounted `noexec`, invoke the script with `sudo bash mitigate_cos_ca_certs.sh` rather than `./mitigate_cos_ca_certs.sh`.

---

## Important Notes

* **Persistence Across Reboots:** Changes made by `mitigate_cos_ca_certs.sh` are **not** persistent across VM reboots.
  * On **GKE**, keep the `cos-ca-cert-mitigator` DaemonSet deployed so the mitigation is automatically re-applied if a node reboots or new nodes are added by the cluster autoscaler.
  * On **standalone COS GCE VMs**, configure a startup script or `cloud-init` config to run `mitigate_cos_ca_certs.sh` on each boot (see [Creating and configuring instances](https://cloud.google.com/container-optimized-os/docs/how-to/create-configure-instance)).
* **Running or Cached Containers:** This script does **not** update running or cached containers that bundle their own root certificates. Pull fixed container images and recreate any containers created from unpatched images.
* **Patched COS Container Utilities:**
  * `gcr.io/cos-cloud/cos-gpu-installer:v2.7.11` (default updated in `cos-extensions`)
  * `gcr.io/cos-cloud/toolbox:v20261020` (default updated in `/etc/default/toolbox`; if you customized `~/.toolboxrc`, update `TOOLBOX_DOCKER_TAG` there as well)
  * `gcr.io/cos-cloud/cos-dkms:v0.3.19`
  * `gcr.io/cos-cloud/cos-customizer:v20261020`
* **`ensurepip`:** This script does not apply mitigations to the bundled `ensurepip` wheel (do not use `python3 -m ensurepip`).
