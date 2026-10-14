#!/bin/sh
# Prometheus does not read credentials from environment variables, only from
# files. This turns the Railway variables into those files at startup, so no
# secret ever lives in this (public) repository.
#
#   PROM_AUTH_HASH      bcrypt hash of the password (htpasswd -nbB performance <password>)
#   PROM_AUTH_PASSWORD  the password itself, used by the self-scrape job
#
# Optional second user, for services that push samples to /api/v1/write from
# outside this Railway project (e.g. a Prometheus agent in another project):
#
#   PROM_WRITE_USER     its name (a-z, 0-9, _ and -)
#   PROM_WRITE_HASH     bcrypt hash of its password
#
# Prometheus basic auth has no per-endpoint permissions: this user can also
# query, exactly like "performance". It exists so each consumer has its own
# credential that can be revoked without touching the others.
set -eu

: "${PROM_AUTH_HASH:?PROM_AUTH_HASH is not set}"
: "${PROM_AUTH_PASSWORD:?PROM_AUTH_PASSWORD is not set}"

umask 077
printf 'basic_auth_users:\n  performance: "%s"\n' "$PROM_AUTH_HASH" > /tmp/web.yml
printf '%s' "$PROM_AUTH_PASSWORD" > /tmp/self-password

if [ -n "${PROM_WRITE_USER:-}${PROM_WRITE_HASH:-}" ]; then
  : "${PROM_WRITE_USER:?PROM_WRITE_USER is not set (PROM_WRITE_HASH needs it)}"
  : "${PROM_WRITE_HASH:?PROM_WRITE_HASH is not set (PROM_WRITE_USER needs it)}"
  case "$PROM_WRITE_USER" in
    performance) echo "PROM_WRITE_USER must not be performance" >&2; exit 1 ;;
    *[!a-z0-9_-]*) echo "PROM_WRITE_USER may only contain a-z, 0-9, _ and -" >&2; exit 1 ;;
  esac
  printf '  %s: "%s"\n' "$PROM_WRITE_USER" "$PROM_WRITE_HASH" >> /tmp/web.yml
fi

# Authentication is always on: --web.config.file is added here and not in CMD,
# so overriding the container arguments cannot turn it off by accident (passing
# it again makes Prometheus refuse to start). Everything else comes from CMD or
# from the arguments given to the container, as in the upstream image.
exec /bin/prometheus --web.config.file=/tmp/web.yml "$@"
