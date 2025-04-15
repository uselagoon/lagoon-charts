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
  additonalEnvs:
    CLEAR_API_DATA: ${clearApiData}

tests:
  image:
    repository: testlagoon/tests
    tag: testing-lesstests
  tests: ${tests}

imageTag: ${imageTag}
