# Lagoon Logging Helm Chart

This chart installs a logging system that will send logs to elasticsearch.

Logs are collated into a single index per lagoon project.

## Requirements

- Helm 3.2.1 or newer

## How to install

Run these commands in the `charts/` directory (above `lagoon-logging/`).

0. Obtain dependency.

```
helm repo add banzaicloud-stable https://kubernetes-charts.banzaicloud.com
helm dependency build lagoon-logging
```

1. Create a `lagoon-logging.values.yaml` file inside `charts/` directory containing these fields with the relevant values added.
   For required values and documentation see the comment block at the end of the chart's `values.yaml`.

**OpenShift only**

You must set allow the fluentbit pods to run in privileged mode, and enable the haproxy logs collector:

```
fluentbitPrivileged: true
openshiftHaproxyLogsCollector:
  enabled: true
```

2. Test installation.

```
helm template --debug --namespace lagoon-logging -f ./lagoon-logging.values.yaml lagoon-logging lagoon-logging
```

```
helm upgrade --dry-run --install --debug --create-namespace --namespace lagoon-logging -f ./lagoon-logging.values.yaml lagoon-logging lagoon-logging
```

3. Run installation.

```
helm upgrade --install --debug --create-namespace --namespace lagoon-logging -f ./lagoon-logging.values.yaml lagoon-logging lagoon-logging
```

**OpenShift only**

Give the various serviceaccounts permissions required:
```
oc project lagoon-logging

# fluentd statefulset serviceaccount (logging-operator chart)
oc adm policy add-scc-to-user nonroot -z lagoon-logging-fluentd

# fluentbit daemonset serviceaccount (logging-operator chart)
oc adm policy add-scc-to-user privileged -z lagoon-logging-fluentbit

# logs-dispatcher statefulset serviceaccount (lagoon-logging chart)
oc adm policy add-scc-to-user anyuid -z lagoon-logging-logs-dispatcher
```

And make the project network global:
```
oc adm pod-network make-projects-global lagoon-logging
```

4. Update application-logs and router-logs services

The `application-logs` and `router-logs` services in the `lagoon` namespace needs to be updated to point their `externalName` to the `lagoon-logging-logs-dispatcher` service in the `lagoon-logging` namespace (or wherever you've installed it).

If you are migrating from the old lagoon logging infrastructure and want to keep logs flowing to both old and new infrastructure, point these services at the relevant `logs-tee` service in the `lagoon-logging` namespace. The `logs-tee` services then need to have the legacy `endpoint` configured. See the comments in the chart `values.yaml` for an example.

## View logs

### For namespaces without a lagoon.sh/project label

Logs will appear in indices matching these patterns:

```
application-logs-*_$CLUSTERNAME-*
container-logs-*_$CLUSTERNAME-*
router-logs-*_$CLUSTERNAME-*
```

e.g. if `clusterName: test1`

```
application-logs-*_test1-*
container-logs-*_test1-*
router-logs-*_test1-*
```

### For namespaces with a lagoon.sh/project label

Logs will appear in indices matching these patterns:

```
application-logs-$PROJECT-*
container-logs-$PROJECT-*
router-logs-$PROJECT-*
```

e.g. if `lagoon.sh/project: drupal-example`

```
application-logs-drupal-example-*
container-logs-drupal-example-*
router-logs-drupal-example-*
```

## How to upgrade

NOTE: If the `logging-operator` chart upgrade doesn't work, just uninstall the helm release and install it again. Logs won't be lost since fluentbit will send the contents of the log files once it is reinstalled.

```
helm upgrade --debug --namespace lagoon-logging --reuse-values lagoon-logging lagoon-logging
```

## Log export

The `logs-dispatcher` includes support for sending logs to external sinks such as [cloudwatch](https://github.com/fluent-plugins-nursery/fluent-plugin-cloudwatch-logs) or [S3](https://docs.fluentd.org/output/s3).
This feature uses the [fluentd copy plugin](https://docs.fluentd.org/output/copy), so see that link for syntax.

For example configure the `exportLogs` value like so:

```
exportLogs:
  s3.conf: |
    <store ignore_error>
      @type s3
      ...
    </store>
  cloudwatch.conf: |
    <store ignore_error>
      @type cloudwatch_logs
      ...
    </store>
```

IMPORTANT: use `ignore_error` so that the main log flow to elasticsearch is not interrupted.

Optionally you may also set `enableDefaultForwarding: false` to disable the default logs forwarding to logs-concentrator and Elasticsearch.

## Local testing

This is useful for quick local testing of `fluent.conf` snippets.

Prerequisite: Ruby gems set up correctly with gems `/bin` dir in `$PATH`.

Install `fluentd`.

```
gem install fluentd
```

Create `fluent.conf`:

```
<source>
  @type                forward
  @id                  in_router_openshift
  tag                  "lagoon.test.router.openshift.unmatched"
</source>

<filter lagoon.*.router.openshift.unmatched>
  @type grep
  <exclude>
    key message
    pattern /my_test_pattern/
  </exclude>
</filter>
# keep the rest
<filter lagoon.*.router.openshift.unmatched>
  @type record_modifier
  <record>
    index_name router-logs-openshift_parse_error_test-${Time.at(time).strftime("%Y.%m")}
  </record>
</filter>

<match lagoon.**>
  @type stdout
</match>
```

Start `fluentd`:

```
fluentd -c fluent.conf
```

Send some test logs:

```
fluent-cat --none tag.discard < sample.log
```
