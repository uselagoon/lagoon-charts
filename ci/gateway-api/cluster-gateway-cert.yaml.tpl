---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-nipio
spec:
  secretName: wildcard-nipio-tls
  isCA: false
  commonName: "*.${GATEWAY_SERVICE}.nip.io"
  dnsNames:
    - "*.${GATEWAY_SERVICE}.nip.io"
  issuerRef:
    kind: ClusterIssuer
    name: lagoon-testing-issuer
