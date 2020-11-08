#!/bin/sh

# # Mac only! TODO: add a check
# brew tap homebrew/cask
# brew cask install keybase
#

# https://keybase.io/docs/the_app/install_linux
cd /tmp
curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
sudo apt --no-install-recommends --no-install-suggests install ./keybase_amd64.deb
run_keybase -g
rm ./keybase_amd64.deb
