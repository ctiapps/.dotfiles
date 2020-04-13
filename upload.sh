#!/bin/bash

REMOTE=$1

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ "${REMOTE}" = "" ]
then
  echo "Please execute this script with parameter that include destination (SSH) user credentials and server name/ip, i.e.:"
  echo "${SCRIPT_PATH}/${SCRIPT_NAME} ak@c0.lt"
  exit
fi

ssh ${REMOTE} 'mkdir -p ~/.dotfiles'
/usr/bin/rsync \
  -avzP \
  --delete \
  --links --safe-links \
  ~/.dotfiles/ ${REMOTE}:~/.dotfiles/
