apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aergia
spec:
  rules:
  - host: aergia.${INGRESS_IP}.nip.io
    http:
      paths:
      - path: "/"
        pathType: Prefix
        backend:
          service:
            name: aergia-backend
            port:
              number: 80