# SPO Seccomp Mitigation for CVE-2026-31431 (Copy Fail)

This directory provides a mitigation for CVE-2026-31431 using the Kubernetes Security Profiles Operator (SPO). It uses a custom `SeccompProfile` that copies containerd's default allowed syscalls but blocks both `AF_VSOCK` and `AF_ALG` (socket family 38).

This is the recommended mitigation for GKE Autopilot clusters and environments where running privileged DaemonSets is not allowed.

## Instructions

**1. Install the Security Profiles Operator (SPO)**
If you do not already have SPO installed in your cluster, follow the installation instructions here:
[SPO Installation & Usage](https://github.com/kubernetes-sigs/security-profiles-operator/blob/main/installation-usage.md)

**2. Deploy the Mitigated Seccomp Profile**
Apply the `seccomp-profile.yaml` to create the profile in your namespace. This profile explicitly denies `AF_ALG` socket creation.
```bash
kubectl apply -f seccomp-profile.yaml
```

**3. Enable Binding on the Namespace**
For the binding to take effect, you must label the target namespace to permit the Security Profiles Operator to modify pods within it:
```bash
kubectl label ns <your-namespace> spo.x-k8s.io/enable-binding=true
```

**4. Bind the Profile to Containers**
Apply the `profile-binding.yaml` to bind the new seccomp profile to all containers in the namespace.
```bash
kubectl apply -f profile-binding.yaml
```

**5. Restart Existing Pods**
The binding is applied via a mutating webhook during pod creation. Existing pods must be restarted or recreated to pick up the new profile and be protected.

---
*Note: We do not recommend relying on containers as a strict security boundary. For stronger isolation, consider using GKE Sandbox.*
