#!/bin/bash

bash -c "docker-compose -v > /dev/null 2>&1"
if [[ $? != 0 ]]; then
  LATEST_URL=`/usr/bin/curl -Ls -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest`
  COMPOSE_VERSION=${LATEST_URL##*/}
  DOWNLOAD_URL=https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`
  /usr/bin/curl -L ${DOWNLOAD_URL} -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "docker-compose is already installed"
fi

