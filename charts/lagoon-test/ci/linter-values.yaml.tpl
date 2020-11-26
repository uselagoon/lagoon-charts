# This template is filled by the test-suite job.
ingressIP: "${ingressIP}"
keycloakAuthServerClientSecret: "${keycloakAuthServerClientSecret}"
routeSuffixHTTP: "${routeSuffixHTTP}"
routeSuffixHTTPS: "${routeSuffixHTTPS}"
token: "${token}"

localGit:
  image:
    repository: testlagoon/local-git

localAPIDataWatcherPusher:
  image:
    repository: testlagoon/local-api-data-watcher-pusher

tests:
  image:
    repository: testlagoon/tests
  suite: "${suite}"

imageTag: main
