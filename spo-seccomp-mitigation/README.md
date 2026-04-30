# Mitigations for CVE-2026-31431 (Copy Fail)

This directory contains mitigation strategies for CVE-2026-31431, a Linux kernel vulnerability that allows an unprivileged local attacker to write to the system page cache, potentially leading to local privilege escalation and container escape. 

While waiting for patched node images to roll out, you can protect your clusters using one of the following methods.

---

## Method 1: Block AF_ALG via Security Profiles Operator (SPO)
**Supported on: GKE Standard, GKE Autopilot, GDC, and Multi-Cloud**

If you are using Autopilot, or if your environment cannot run privileged DaemonSets, you can block workloads from creating the `AF_ALG` sockets required for the exploit using a custom seccomp profile.

**1. Install the Security Profiles Operator (SPO)**
If you do not already have SPO installed, follow the [SPO Installation & Usage Guide](https://github.com/kubernetes-sigs/security-profiles-operator/blob/main/installation-usage.md).

**2. Deploy the Mitigated Seccomp Profile**
Apply `seccomp-profile.yaml` to create the profile. This profile explicitly denies `AF_ALG` (socket family 38) and `AF_VSOCK` socket creation.
```bash
kubectl apply -f seccomp-profile.yaml
```

**3. Enable Binding on the Namespace**
Label your target namespaces to permit SPO to modify pods within them:
```bash
kubectl label ns <your-namespace> spo.x-k8s.io/enable-binding=true
```

**4. Bind the Profile to Containers**
Apply `profile-binding.yaml` to bind the new seccomp profile to all containers in the namespace.
```bash
kubectl apply -f profile-binding.yaml
```

**5. Restart Existing Pods**
The binding is applied via a mutating webhook during pod creation. Existing pods must be restarted or recreated to pick up the new profile.

---

## Method 2: Blacklist the kernel module via DaemonSet
**Supported on: GKE Standard (with limitations)**

For GKE Standard clusters, you can deploy a privileged DaemonSet that edits the node's `/etc/modprobe.d` configuration to blacklist the vulnerable `algif_aead` module and sets the `initcall_blacklist=algif_aead_init` kernel parameter. 

### ⚠️ Known Limitations & Caveats
Please be aware of the following issues before deploying this DaemonSet:
* **Secure Boot:** This mitigation does not work if Secure Boot is enabled. The DaemonSet will enter an `Init:CrashLoopBackOff` state because Secure Boot prevents changes to the kernel command line boot options.
* **Spot Nodes:** This mitigation is currently failing on Spot (Preemptible VM) nodes due to cgroup configuration errors during container initialization.
* **Node Reboots:** Applying this DaemonSet will immediately reboot the affected nodes. 

**Deployment:**
To control the rollout, label your target nodes first:
```bash
kubectl label nodes <node-name> cloud.google.com/gke-algif-aead-disabled=true
```
Then, apply the DaemonSet:
```bash
kubectl apply -f daemonset.yaml
```

---
*Note: We do not recommend relying on containers as a strict security boundary. For stronger isolation, consider using GKE Sandbox.*
