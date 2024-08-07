# Containerd Debugging Logging

The `containerd-debug-logging-daemonset.yaml` is a daemonset that enables
containerd debug logs. These logs may be useful for troubleshooting. Note that
debug logs are quite verbose and such increase log volume for these logs.

The daemonset includes a nodeSelector targeting
`containerd-debug-logging=true`. To run the daemonset on selected nodes for
debugging, labels the nodes with the corresponding label (`kubectl label node
${NODE_NAME} containerd-debug-logging=true`)

Otherwise, modify the daemonset's existing
[nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)
or add an [node
affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)
to target the desired nodes or node pools.
