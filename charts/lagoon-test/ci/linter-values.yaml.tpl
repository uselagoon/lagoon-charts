# This template is filled by the test-suite job.
ingressIP: "${ingressIP}"
keycloakAuthServerClientSecret: "${keycloakAuthServerClientSecret}"
routeSuffixHTTP: "${routeSuffixHTTP}"
routeSuffixHTTPS: "${routeSuffixHTTPS}"
token: "${token}"
webhookHost: "${webhookHandler}"
webhookRepoPrefix: "${webhookRepoPrefix}"

localGit:
  image:
    repository: ${imageRegistry}/local-git

localAPIDataWatcherPusher:
  image:
    repository: ${imageRegistry}/local-api-data-watcher-pusher

tests:
  image:
    repository: testlagoon/tests
    tag: pr-2437
  tests: ${tests}

imageTag: ${imageTag}
