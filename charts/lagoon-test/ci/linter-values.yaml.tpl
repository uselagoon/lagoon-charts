# This template is filled by the test-suite job.
ingressIP: "${ingressIP}"
keycloakAuthServerClientSecret: "${keycloakAuthServerClientSecret}"
routeSuffixHTTP: "${routeSuffixHTTP}"
routeSuffixHTTPS: "${routeSuffixHTTPS}"
token: "${token}"

localGit:
  image:
    repository: ${imageRegistry}/local-git

localAPIDataWatcherPusher:
  image:
    repository: ${imageRegistry}/local-api-data-watcher-pusher

tests:
  image:
    repository: testlagoon/tests
    tag: test-timeout-bumps
  tests: ${tests}

imageTag: ${imageTag}
