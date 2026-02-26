apiVersion: v1
kind: ConfigMap
metadata:
  name: errorfile
data:
  503: |-
    HTTP/1.0 503 Service Unavailable
    Cache-Control: no-cache
    Connection: close
    Content-Type: text/html

    <!DOCTYPE html>
    <html>
    <head>
        <title>Redirecting...</title>
        <meta http-equiv="refresh" content="0; url=https://aergia.${INGRESS_IP}.nip.io/?unidle=true" />
        <link rel="canonical" href="https://aergia.${INGRESS_IP}.nip.io" />
    </head>
    <body>
        <p>If you are not redirected automatically, follow this <a href="https://aergia.${INGRESS_IP}.nip.io/?unidle=true">link to the destination page</a>.</p>
    </body>
    </html>