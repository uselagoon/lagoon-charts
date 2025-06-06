apiVersion: apps/v1
kind: Deployment
metadata:
  name: coffee
spec:
  replicas: 1
  selector:
    matchLabels:
      app: coffee
  template:
    metadata:
      labels:
        app: coffee
    spec:
      containers:
      - name: coffee
        image: nginxdemos/nginx-hello:plain-text
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: coffee
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: coffee
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tea
  template:
    metadata:
      labels:
        app: tea
    spec:
      containers:
      - name: tea
        image: nginxdemos/nginx-hello:plain-text
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: tea
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: tea
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: coffee
spec:
  parentRefs:
  - name: gateway
    sectionName: http
    namespace: nginx-gateway
  - name: gateway
    sectionName: https
    namespace: nginx-gateway
  hostnames:
  - "cafe.${GATEWAY_SERVICE}.nip.io"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: coffee
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: tea
spec:
  parentRefs:
  - name: gateway
    sectionName: http
    namespace: nginx-gateway
  - name: gateway
    sectionName: https
    namespace: nginx-gateway
  hostnames:
  - "cafe.${GATEWAY_SERVICE}.nip.io"
  rules:
  - matches:
    - path:
        type: Exact
        value: /tea
    backendRefs:
    - name: tea
      port: 80
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: cafe-cert
# spec:
#   secretName: cafe-cert-tls
#   isCA: false
#   usages:
#     - server auth
#     - client auth
#   commonName: "cafe.${GATEWAY_SERVICE}.nip.io"
#   dnsNames:
#     - "cafe.${GATEWAY_SERVICE}.nip.io"
#   issuerRef:
#     kind: ClusterIssuer
#     name: lagoon-testing-issuer
# ---
## ListenerSet doesn't appear to be supported by nginx gateway yet (https://gateway-api.sigs.k8s.io/geps/gep-1713/ for gatewayapi implementation)
## without this feature, we are blocked on the ability to do TLS as a application developer (https://gateway-api.sigs.k8s.io/concepts/roles-and-personas/#key-roles-and-personas)
## due to gatewayapi only allowing the gateway resource to be able to assign certificates to a listener, rather than the previous method of directly on an ingress
## HTTPRoute does nothing with TLS
# apiVersion: gateway.networking.x-k8s.io/v1alpha1
# kind: XListenerSet
# metadata:
#   name: cafe-listener
# spec:
#   parentRef:
#     name: gateway
#     kind: Gateway
#     group: gateway.networking.k8s.io
#     namespace: nginx-gateway
#   listeners:
#   - name: https
#     hostname: "cafe.${GATEWAY_SERVICE}.nip.io"
#     protocol: HTTPS
#     port: 443
#     tls:
#       mode: Terminate
#       certificateRefs:
#       - kind: Secret
#         group: ""
#         name: cafe-cert-tls