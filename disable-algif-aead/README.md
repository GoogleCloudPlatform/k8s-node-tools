# DaemonSet Mitigation for CVE-2026-31431 (Copy Fail)

This directory contains a privileged DaemonSet mitigation for CVE-2026-31431. It edits the node's `/etc/modprobe.d` configuration to blacklist the vulnerable `algif_aead` module and sets the `initcall_blacklist=algif_aead_init` kernel parameter.

### ⚠️ Known Limitations & Caveats
Please be aware of the following issues before deploying this DaemonSet:
* **Secure Boot:** This mitigation does not work if Secure Boot is enabled. The DaemonSet will enter an `Init:CrashLoopBackOff` state because Secure Boot prevents changes to the kernel command line boot options.
* **Spot Nodes:** This mitigation is currently failing on Spot (Preemptible VM) nodes due to cgroup configuration errors during container initialization.
* **Node Reboots:** Applying this DaemonSet will immediately reboot the affected nodes. 

## Deployment Instructions

**1. Label your target nodes:**
To control the rollout, label your target nodes first:
```bash
kubectl label nodes <node-name> cloud.google.com/gke-algif-aead-disabled=true
```

**2. Apply the DaemonSet:**
```bash
kubectl apply -f daemonset.yaml
```

---

Note: We do not recommend relying on containers as a strict security boundary. For stronger isolation, consider using GKE Sandbox.
