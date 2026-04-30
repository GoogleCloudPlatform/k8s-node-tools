# DaemonSet Mitigation for CVE-2026-31431 (Copy Fail)

This directory contains a privileged DaemonSet mitigation for CVE-2026-31431. It edits the node's `/etc/modprobe.d` configuration to blacklist the vulnerable `algif_aead` module and sets the `initcall_blacklist=algif_aead_init` kernel parameter. This does not change the behavior of `/etc/modprobe.d`.

### ⚠️ Known Limitations & Caveats
Please be aware of the following issues before deploying this DaemonSet:
* **Secure Boot:** This mitigation does not work if Secure Boot is enabled. The init container will never finish initializing because Secure Boot prevents changes to the kernel command line boot options.
* **Spot Nodes:** We've received reports that this mitigation is currently failing on Spot (Preemptible VM) nodes due to cgroup configuration errors during container initialization, however we have been unable to reproduce this.
* **Node Reboots:** Applying this DaemonSet will immediately reboot the affected nodes. 

## Deployment Instructions

**1. Label your target nodes:**
To control the rollout, label your target nodes first:
```bash
kubectl label nodes <node-name> cloud.google.com/gke-algif-aead-disabled=true
```

**2. Apply the DaemonSet:**
```bash
kubectl apply -f cos-disable-algif-aead.yaml
```

---

Note: We do not recommend relying on containers as a strict security boundary. For stronger isolation, consider using GKE Sandbox, network policies and the guidance found at https://docs.cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster.
