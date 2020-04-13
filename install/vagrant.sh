#!/usr/bin/env bash

cd /tmp
/usr/bin/wget https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.deb
dpkg -i vagrant_2.2.7_x86_64.deb
