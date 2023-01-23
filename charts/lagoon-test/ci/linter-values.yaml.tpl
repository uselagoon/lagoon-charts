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

# localAPIDataWatcherPusher:
#   image:
#     repository: ${imageRegistry}/local-api-data-watcher-pusher

localAPIDataWatcherPusher:
  image:
    repository: testlagoon/local-api-data-watcher-pusher
    tag: main

# tests:
#   image:
#     repository: ${imageRegistry}/tests
#   tests: ${tests}

tests:
  image:
    repository: testlagoon/tests
    tag: main
  tests: ${tests}

imageTag: ${imageTag}
