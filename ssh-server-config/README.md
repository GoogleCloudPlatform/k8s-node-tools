The ssh-server-config tool is a Kubernates DaemonSet that set [loginGraceTime](https://man.openbsd.org/sshd#g) to 0.

## :warning: This configuration may increase the risk of denial of service attacks and may cause issues with legitimate SSH access.

## How to use it?
Apply it to all nodes in your cluster by running the
following command. Run the command once per cluster per
Google Cloud Platform project.

### GKE Clusters

```
kubectl apply -f \
https://raw.githubusercontent.com/GoogleCloudPlatform\
/k8s-node-tools/master/ssh-server-config/set-login-grace-time.yaml
```

### GDC software-only for VMware Clusters

```
kubectl apply -f \
https://raw.githubusercontent.com/GoogleCloudPlatform\
/k8s-node-tools/master/ssh-server-config/set-login-grace-time-gdcso-vmware.yaml
```

## How to get the result?
Run the command below to get related log.
```
kubectl -n kube-system logs -l app=ssh-server-config -c ssh-server-config
```
