#!/usr/bin/env bash

set -x

LINUX_USER="${LINUX_USER:-pi}"
LINUX_USER_HOME="${LINUX_USER_HOME}/home/${LINUX_USER}"

################################################################################
## Time must be syncronized on Raspberry Pi
##
apt-get -yqq install ntpdate
# europe.pool.ntp.org
ntpdate pool.ntp.org
timedatectl set-ntp True

################################################################################
## Installing dependencies and utilities
##
apt-get update
apt-get -yqq upgrade
apt-get -yqq autoremove

apt-get -yqq --no-install-recommends --no-install-suggests install \
  ca-certificates \
  curl \
  git \
  mc \
  mtr-tiny \
  net-tools \
  nmap \
  openssl \
  rsync

################################################################################
## Installing docker
##

apt-get -yqq --no-install-recommends --no-install-suggests install \
  libffi-dev \
  libssl-dev \
  python3 \
  python3-pip \
  python3-setuptools

docker -v > /dev/null 2>&1
if [[ $? != 0 ]]; then
  curl -sSL https://get.docker.com | sh
  usermod -aG docker "${LINUX_USER}"
fi

pip3 -v install --upgrade docker-compose

################################################################################
## Clone and bootstrap dotfiles
##
if [ ! -d "${LINUX_USER_HOME}/.dotfiles" ] ; then
  if [ ! -d "${HOME}/.dotfiles" ] ; then
    git clone https://github.com/andrius/.dotfiles.git ${LINUX_USER_HOME}/.dotfiles
  else
    cp -R ${HOME}/.dotfiles ${LINUX_USER_HOME}/
  fi
else
  echo ".dotfiles folder is already there, trying to update"
  cd "${LINUX_USER_HOME}/.dotfiles"
  git fetch --all
  git pull
fi

cd "${LINUX_USER_HOME}/.dotfiles"
mkdir -p local
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.dotfiles

################################################################################
## tmux
##
apt-get -yqq --no-install-recommends --no-install-suggests install \
  tmux

# Symlink .tmux folder
rm -rf ${LINUX_USER_HOME}/.tmux ${LINUX_USER_HOME}/.tmux.conf
ln -s ${LINUX_USER_HOME}/.dotfiles/tmux ${LINUX_USER_HOME}/.tmux
ln -s ${LINUX_USER_HOME}/.tmux/tmux.conf ${LINUX_USER_HOME}/.tmux.conf
# Create samlpe tmux user.conf
cp ${LINUX_USER_HOME}/.tmux/user.conf-sample ${LINUX_USER_HOME}/.tmux/user.conf
# Clone tmux plugins
cd ${LINUX_USER_HOME}/.dotfiles/tmux
mkdir -p plugins data
cd plugins
git clone https://github.com/tmux-plugins/tpm.git tpm
git clone https://github.com/tmux-plugins/tmux-resurrect tmux-resurrect
git clone https://github.com/tmux-plugins/tmux-yank tmux-yank
cd
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.tmux ${LINUX_USER_HOME}/.tmux.conf

################################################################################
## zsh
##

apt-get -yqq --no-install-recommends --no-install-suggests install \
  zsh

chsh --shell $(which zsh) root
chsh --shell $(which zsh) "${LINUX_USER}"

cat <<EOT > ${LINUX_USER_HOME}/.zshrc

# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/bin" ] ; then
    PATH="\$HOME/bin:\$PATH"
fi
if [ -d "\$HOME/.dotfiles/bin" ] ; then
    PATH="\$HOME/.dotfiles/bin:\$PATH"
fi

# Uncomment if there would be issues with TERM
# case $TERM in screen-256*) TERM=screen;; esac
# case $TERM in tmux-256*)   TERM=screen;; esac
EOT

chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.zshrc

su - ${LINUX_USER} sh -c "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh"
rm ${LINUX_USER_HOME}/.bash*
rm ${LINUX_USER_HOME}/.profile

################################################################################
## neovim
##

apt-get -yqq --no-install-recommends --no-install-suggests install \
  neovim \
  python3 \
  python3-venv \
  ruby

su - ${LINUX_USER} zsh -c """
source ~/.zshrc; \\
pip3 install --user --upgrade virtualenv \\
pip3 install --user --upgrade pynvim \\
pip3 install --user --upgrade neovim \\
gem install --no-document --user-install neovim
"""

# We use rafi nvim config with some modifications
mkdir -p ${LINUX_USER_HOME}/.config
git clone git://github.com/rafi/vim-config.git ${LINUX_USER_HOME}/.config/nvim
ln -s ${LINUX_USER_HOME}/.config/nvim ${LINUX_USER_HOME}/.vim
ln -s ${LINUX_USER_HOME}/.dotfiles/config/nvim/config/local.vim ${LINUX_USER_HOME}/.config/nvim/config/local.vim
ln -s ${LINUX_USER_HOME}/.dotfiles/config/nvim/config/local.plugins.yaml ${LINUX_USER_HOME}/.config/nvim/config/local.plugins.yaml
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.config
su - ${LINUX_USER} zsh -c """
source ~/.zshrc && cd ~/.config/nvim && ./venv.sh && make
"""

################################################################################
## Post-install
##
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/
apt-get clean all
${LINUX_USER_HOME}/.dotfiles/bin/purge-system-logfiles
