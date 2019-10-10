The check-legacy-endpoint-access tool is a Kubernates DaemonSet that checks metadata server 
legacy access count of computeMetadata/0.1 and
computeMetadata/v1beta1 every five minutes and writes the result to logs.

## How to use it?
Apply it to all nodes in your cluster by running the
following command. Run the command once per cluster per
Google Cloud Platform project.
```
kubectl apply -f \
https://raw.githubusercontent.com/GoogleCloudPlatform\
/k8s-node-tools/master/check-legacy-endpoint-access/check-legacy-endpoint-access.yaml
```
## How to get the result?
Run the command below to get related log.
```
kubectl -n kube-system logs -l app=check-legacy-endpoint-access | grep "access
count"
```
Below is a sample log entry
```
2019-10-17 20:35:12 for node gke-someone-k8s-default-pool-484b3c6d-csgj.c.someone-dev.internal, legacy access count of computeMetadata/0.1 is: 0, legacy access count of computeMetadata/v1beta1 is: 2
```
If you want to see log history, you can go to GCP console -> Logs Viewer and use
the filter as below
```
resource.type="container"
resource.labels.namespace_id="kube-system"
logName:"/check-legacy-endpoint-access"
```
