kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: chart-testing
nodes:
- role: control-plane
  image: kindest/node:v1.31.4@sha256:2cb39f7295fe7eafee0842b1052a599a4fb0f8bcf3f83d96c7f4864c357c6c30
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.${KIND_NODE_IP}.nip.io".tls]
    insecure_skip_verify = true
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.${KIND_NODE_IP}.nip.io"]
    endpoint = ["http://registry.${KIND_NODE_IP}.nip.io"]
