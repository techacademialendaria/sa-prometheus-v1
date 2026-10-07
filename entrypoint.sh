#!/bin/sh
# Prometheus does not read credentials from environment variables, only from
# files. This turns the Railway variables into those files at startup, so no
# secret ever lives in this (public) repository.
#
#   PROM_AUTH_HASH      bcrypt hash of the password (htpasswd -nbB superagentes <password>)
#   PROM_AUTH_PASSWORD  the password itself, used by the self-scrape job
set -eu

: "${PROM_AUTH_HASH:?PROM_AUTH_HASH is not set}"
: "${PROM_AUTH_PASSWORD:?PROM_AUTH_PASSWORD is not set}"

umask 077
printf 'basic_auth_users:\n  superagentes: "%s"\n' "$PROM_AUTH_HASH" > /tmp/web.yml
printf '%s' "$PROM_AUTH_PASSWORD" > /tmp/self-password

exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=30d \
  --web.config.file=/tmp/web.yml
