#!/bin/sh
# Prometheus does not read credentials from environment variables, only from
# files. This turns the Railway variables into those files at startup, so no
# secret ever lives in this (public) repository.
#
#   PROM_AUTH_HASH      bcrypt hash of the password (htpasswd -nbB performance <password>)
#   PROM_AUTH_PASSWORD  the password itself, used by the self-scrape job
set -eu

: "${PROM_AUTH_HASH:?PROM_AUTH_HASH is not set}"
: "${PROM_AUTH_PASSWORD:?PROM_AUTH_PASSWORD is not set}"

umask 077
printf 'basic_auth_users:\n  performance: "%s"\n' "$PROM_AUTH_HASH" > /tmp/web.yml
printf '%s' "$PROM_AUTH_PASSWORD" > /tmp/self-password

# Authentication is always on: --web.config.file is added here and not in CMD,
# so overriding the container arguments cannot turn it off by accident (passing
# it again makes Prometheus refuse to start). Everything else comes from CMD or
# from the arguments given to the container, as in the upstream image.
exec /bin/prometheus --web.config.file=/tmp/web.yml "$@"
