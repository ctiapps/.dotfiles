#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
cd "$(dirname "${BASH_SOURCE[0]}")"

REMOTE=$1
if [ "${REMOTE}" = "" ]
then
  echo "Please execute this script with parameter that include destination (SSH) user credentials and server name/ip, i.e.:"
  echo "${SCRIPT_PATH}/${SCRIPT_NAME} ak@c0.lt"
  exit
fi

# DRY_RUN=--dry-run
DRY_RUN=
TIMEOUT=20
RSYNC_SKIP_COMPRESS=3fr/3g2/3gp/3gpp/7z/aac/ace/amr/apk/appx/appxbundle/arc/arj/arw/asf/avi/bz/bz2/cab/cr2/crypt[5678]/dat/dcr/deb/dmg/drc/ear/erf/flac/flv/gif/gpg/gz/iiq/jar/jp2/jpeg/jpg/h26[45]/k25/kdc/kgb/lha/lz/lzma/lzo/lzx/m4[apv]/mef/mkv/mos/mov/mp[34]/mpeg/mp[gv]/msi/nef/oga/ogg/ogv/opus/orf/pak/pef/png/qt/rar/r[0-9][0-9]/rz/rpm/rw2/rzip/sfark/sfx/s7z/sr2/srf/svgz/t[gb]z/tlz/txz/vob/wim/wma/wmv/xz/zip

ssh ${REMOTE} 'apt-get update && apt-get install -yqq --no-install-recommends --no-install-suggests rsync screen curl ca-certificates'
ssh ${REMOTE} 'mkdir -p ~/.dotfiles' && \
# /usr/bin/rsync ${DRY_RUN} -aHAXxvP \
#   --skip-compress=${RSYNC_SKIP_COMPRESS} \
/usr/bin/rsync ${DRY_RUN} -avzP \
  --links \
  --numeric-ids \
  --delete \
  --timeout=${TIMEOUT} \
  --force \
  -e "ssh -T -c aes256-gcm@openssh.com -o Compression=no -x -i ~/.ssh/id_ed25519" \
  ~/.dotfiles/ ${REMOTE}:~/.dotfiles/
