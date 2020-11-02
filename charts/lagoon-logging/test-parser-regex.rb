#!/usr/bin/env ruby

# This script is for testing the regex used to parse haproxy logs.
# Successfully parsed lines are printed to STDOUT.
# Unmatched lines are prefixed with "ERROR matching: ".
#
# Usage:
#   ./test-parser-regex.rb /tmp/haproxy.log
#   OR
#   ./test-parser-regex.rb < /tmp/haproxy.log

# current haproxy regex copied from the fluentd configmap
regex = /^.{,15} (?<process_name>\w+)\[(?<pid>\d+)\]: (?<client_ip>\S+):(?<client_port>\d+) \[(?<request_date>\S+)\] (?<frontend_name>\S+) (?<backend_type>\S+):(?<docker_container_id>(?<kubernetes_namespace_name>\S+):\S+\/pod:(?<kubernetes_pod_name>[^:]+):(?<kubernetes_container_name>[^:]+)):\S+ (?<TR>[\d-]+)\/(?<Tw>[\d-]+)\/(?<Tc>[\d-]+)\/(?<Tr>[\d-]+)\/(?<Ta>[\d+-]+) (?<status_code>\d+) (?<bytes_read>[\d+]+) (?<captured_request_cookie>\S+) (?<captured_response_cookie>\S+) (?<termination_state>\S+) (?<actconn>\d+)\/(?<feconn>\d+)\/(?<beconn>\d+)\/(?<srv_conn>\d+)\/(?<retries>\d+) (?<srv_queue>\d+)\/(?<backend_queue>\d+) (\{(?<request_host>.+)\|(?<request_user_agent>.+)?\} )?"(?<http_request>(?<http_request_method>\S+) (?<http_request_path>\S+)(?: (?<http_request_version>.+))?)"/

# another example: the nginx parsing regex used by fluentd
# based on https://docs.fluentd.org/parser/nginx#regexp-patterns, but with some
# tweaks for forwarded_for.
# regex = /^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*?)(?: +\S*)?)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)"(?:\s+"(?<forwarded_for>[^"]+)")?)?$/

while input = ARGF.gets
  input.each_line do |line|
    if matchdata = regex.match(line)
      p matchdata
    else
      puts "ERROR matching: #{line}"
    end
  end
end
