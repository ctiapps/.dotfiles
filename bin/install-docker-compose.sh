#!/usr/bin/env bash
# vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab filetype=sh fileencoding=utf-8 :
set -x

LATEST_URL="$(curl -Ls -o /dev/null -w '%{url_effective}' https://github.com/docker/compose/releases/latest)"
[ "${1}" == "" ] && COMPOSE_VERSION="${LATEST_URL##*/}" || COMPOSE_VERSION="$1"
DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
sudo rm -f /usr/local/bin/docker-compose
sudo curl -L "${DOWNLOAD_URL}" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -v > /dev/null 2>&1 || echo "There is issues with docker-compose, please check!"
