#!/usr/bin/env bash
# vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab filetype=sh fileencoding=utf-8 :
set -ueox pipefail

set -e
LATEST_URL="$(curl -Ls -o /dev/null -w '%{url_effective}' https://github.com/docker/compose/releases/latest)"
COMPOSE_VERSION="${LATEST_URL##*/}"
DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
sudo curl -L "${DOWNLOAD_URL}" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
set +e
docker-compose -v > /dev/null 2>&1 || echo "There is issues with docker-compose, please check!"
set -e

