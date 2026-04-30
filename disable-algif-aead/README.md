# Mitigation Advice for CVE-2026-31431 (Copy Fail)

This document provides immediate mitigation steps for CVE-2026-31431. While waiting for patched node images to roll out, you can protect your clusters using the following methods.

## GKE Standard Nodes running Container-Optimized OS (COS)
For GKE Standard nodes running Container-Optimized OS, you can set the `initcall_blacklist=algif_aead_init` kernel parameter on your nodes to disable the impacted functionality. 

You can apply the privileged DaemonSet (`cos-disable-algif-aead.yaml`) provided in this directory to set this kernel parameter. Be mindful that this tool immediately reboots nodes; you can use the `cloud.google.com/gke-algif-aead-disabled` node label to control the application of the DaemonSet. This option will block legitimate usage of this kernel behavior as well as malicious usage.

**Deployment Instructions:**
1. Label your target nodes to control the rollout:
```bash
kubectl label nodes <node-name> cloud.google.com/gke-algif-aead-disabled=true
```
2. Apply the DaemonSet:
```bash
kubectl apply -f cos-disable-algif-aead.yaml
```

### ⚠️ Known Limitations
* **Secure Boot:** This mitigation does not work if Secure Boot is enabled. The init container will never finish initializing because Secure Boot prevents changes to the kernel command line boot options.
* **Spot Nodes:** We've received reports that this mitigation is intermittently failing on Spot (Preemptible VM) nodes due to cgroup configuration errors during container initialization, however we have been unable to reproduce this.
* **Node Reboots:** Applying this DaemonSet will immediately reboot the affected nodes.

## GKE Standard Nodes running Ubuntu
For GKE Standard nodes running Ubuntu, you can blacklist the `algif_aead` module on your nodes (for example, by using a privileged DaemonSet) with the following commands:

```bash
echo "install algif_aead /bin/false" > /etc/modprobe.d/disable-algif-aead.conf
rmmod algif_aead 2>/dev/null
```

## GKE Autopilot (and Alternative for Standard)
GKE Autopilot does not allow running privileged daemonsets, and therefore must be mitigated by applying a [custom seccomp profile to your workloads to block AF_ALG socket creation](../spo-seccomp-mitigation). This also works as an alternative mitigation method for GKE Standard clusters.

---
*Note: We do not recommend relying on containers as a strict security boundary. For stronger isolation, consider using GKE Sandbox, network policies and the guidance found at [https://docs.cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster).*
