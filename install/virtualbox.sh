#!/usr/bin/env bash

echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" > /etc/apt/sources.list.d/virtualbox.list
/usr/bin/wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
apt-get update
apt-get -yqq --no-install-recommends --no-install-suggests install \
  build-essential \
  dkms \
  linux-headers-$(uname -r) \
  virtualbox-6.1
cd /tmp
/usr/bin/wget https://download.virtualbox.org/virtualbox/6.1.4/Oracle_VM_VirtualBox_Extension_Pack-6.1.4.vbox-extpack
usermod -aG vboxusers ${USER}
