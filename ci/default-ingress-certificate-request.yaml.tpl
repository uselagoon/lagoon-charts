apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: default-ingress-certificate
spec:
  secretName: default-ingress-certificate-tls
  isCA: false
  usages:
    - server auth
  dnsNames:
  - '*.${INGRESS_IP}.nip.io'
  - '${INGRESS_IP}.nip.io'
  issuerRef:
    kind: ClusterIssuer
    name: lagoon-testing-issuer