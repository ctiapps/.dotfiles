#!/usr/bin/env bash

apt-get install ntpd
# europe.pool.ntp.org
ntpdate es.pool.ntp.org
apt-get update
apt-get dist-upgrade
apt-get -yqq --no-install-recommends --no-install-suggests install \
  tmux \
  neovim \
  zsh \
  git \
  curl
curl -sSL https://get.docker.com | sh
usermod -aG docker pi

set +e
bash -c "docker-compose -v > /dev/null 2>&1"
if [[ $? != 0 ]]; then
  set -e
  LATEST_URL=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest`
  COMPOSE_VERSION=${LATEST_URL##*/}
  DOWNLOAD_URL=https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`
  curl -L ${DOWNLOAD_URL} -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  set -e
  echo "docker-compose already installed"
fi

apt-get clean all
