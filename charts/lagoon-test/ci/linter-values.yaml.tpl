# This template is filled by the test-suite job.
ingressIP: "${ingressIP}"
keycloakAuthServerClientSecret: "${keycloakAuthServerClientSecret}"
routeSuffixHTTP: "${routeSuffixHTTP}"
routeSuffixHTTPS: "${routeSuffixHTTPS}"
token: "${token}"

localAPIDataWatcherPusher:
  # TODO: remove this once a 2.x release is the chart appVersion
  image:
    tag: "main"

tests:
  # TODO: remove this once a 2.x release is the chart appVersion
  image:
    tag: "main"
