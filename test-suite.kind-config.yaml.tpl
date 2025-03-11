kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: chart-testing
nodes:
- role: control-plane
  image: kindest/node:v1.31.6@sha256:28b7cbb993dfe093c76641a0c95807637213c9109b761f1d422c2400e22b8e87
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.${KIND_NODE_IP}.nip.io".tls]
    insecure_skip_verify = true
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.${KIND_NODE_IP}.nip.io"]
    endpoint = ["http://registry.${KIND_NODE_IP}.nip.io"]
