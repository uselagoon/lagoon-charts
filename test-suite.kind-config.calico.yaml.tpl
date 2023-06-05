kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: chart-testing
networking:
  disableDefaultCNI: true
  podSubnet: 192.168.0.0/16
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.${KIND_NODE_IP}.nip.io:32443".tls]
    insecure_skip_verify = true
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.${KIND_NODE_IP}.nip.io:32080"]
    endpoint = ["http://registry.${KIND_NODE_IP}.nip.io:32080"]
