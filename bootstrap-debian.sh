#!/bin/bash

## Installation instructions
## If you trust in one-liner installers, then copy/paste following line (OR clone this gist, exit and execute):
##
# apt-get update && apt-get -yqq --no-install-recommends --no-install-suggests install curl ca-cacert
#
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/andrius/.dotfiles/master/bootstrap-debian.sh)"

set -ex

################################################################################
## Settings
##
LINUX_USER="${LINUX_USER:-ak}"
# TODO: set password (as for now its passwordless with ssh key authentication)
# set +e
# read -t 10 -p "Please enter login password for new user and hit Enter" LINUX_USER_PASSWORD
# set -e


################################################################################
## Installing linuxbrew dependences
##
apt-get update
apt-get -yqq upgrade
apt-get -yqq autoremove

DEBIAN_FRONTEND=noninteractive \
apt-get -yqq --no-install-recommends --no-install-suggests install \
  build-essential \
  ca-cacert \
  ca-certificates \
  curl \
  file \
  git \
  mtr-tiny \
  net-tools \
  openssl \
  sudo

set +e
read -t 10 -p "Type 'reboot' and hit ENTER, if you want to reboot after upgrade/install, or just press ENTER to continue installation\n" res
set -e
if [ "$res" != "" ]
then
  echo "Rebooting, you'll need to run this script again after that..."
  reboot
fi


################################################################################
## Creating Linux user if not exist
##
set +e
getent passwd ${LINUX_USER} >/dev/null 2>&1
if [ $? -eq 0 ]; then
  set -e
  echo "User ${LINUX_USER} already exists"
else
  set -e
  echo "Creating user ${LINUX_USER}"
  adduser \
    --quiet \
    --home /home/${LINUX_USER} \
    --shell /bin/bash \
    --gecos '' \
    --disabled-password \
    --add_extra_groups \
    ${LINUX_USER}
fi
usermod -aG sudo ${LINUX_USER}
echo "${LINUX_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${LINUX_USER}; \
chmod 0440 /etc/sudoers.d/${LINUX_USER};


################################################################################
## Installing docker
##

set +e
bash -c "docker -v > /dev/null 2>&1"
if [[ $? != 0 ]]; then
  set -e
  curl -sSL https://get.docker.com/ | sh
  usermod -aG docker ${LINUX_USER}
  LATEST_URL=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest`
  COMPOSE_VERSION=${LATEST_URL##*/}
  DOWNLOAD_URL=https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`
  curl -L ${DOWNLOAD_URL} -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  set -e
  echo "Docker already installed"
fi


################################################################################
## Installing Linuxbrew
##

# make brew command available for root user too
echo -e "#/bin/sh\n\nsu - ${LINUX_USER} --shell `which bash` /home/linuxbrew/.linuxbrew/bin/brew \$@" > /usr/bin/brew
chmod +x /usr/bin/brew

set +e
# rm -rf /home/linuxbrew/.linuxbrew
mkdir -p /home/linuxbrew/.linuxbrew \
&& (
  chown -R ${LINUX_USER}:${LINUX_USER} /home/linuxbrew/.linuxbrew
  su - ${LINUX_USER} --shell `which bash` -c 'git clone https://github.com/Homebrew/brew.git /home/linuxbrew/.linuxbrew'

  echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"'      >> /home/${LINUX_USER}/.profile
  echo 'export MANPATH="$(brew --prefix)/share/man:$MANPATH"'    >> /home/${LINUX_USER}/.profile
  echo 'export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"' >> /home/${LINUX_USER}/.profile
)

brew
set -e

# brew recommend to install gcc
brew install gcc


################################################################################
## zsh
##
apt-get -yqq purge zsh*
rm -rf /usr/bin/zsh
brew install zsh
ln -s /home/linuxbrew/.linuxbrew/bin/zsh /usr/bin/zsh >/dev/null 2>&1
grep -q -F '/usr/bin/zsh' /etc/shells || echo '/usr/bin/zsh' >> /etc/shells
chsh -s /usr/bin/zsh ${LINUX_USER}

cat <<EOT > /home/${LINUX_USER}/.zshrc

# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/bin" ] ; then
    PATH="\$HOME/bin:\$PATH"
fi
if [ -d "\$HOME/.dotfiles/bin" ] ; then
    PATH="\$HOME/.dotfiles/bin:\$PATH"
fi

export PATH="/home/linuxbrew/.linuxbrew/bin:\$PATH"
export MANPATH="\$(brew --prefix)/share/man:\$MANPATH"
export INFOPATH="\$(brew --prefix)/share/info:\$INFOPATH"

# Uncomment if there would be issues with TERM
# case $TERM in screen-256*) TERM=screen;; esac
# case $TERM in tmux-256*)   TERM=screen;; esac
EOT
chown -R ${LINUX_USER}:${LINUX_USER} /home/${LINUX_USER}/.zshrc

cat <<EOT > /tmp/zim-install.zsh
rm -rf \${ZDOTDIR:-\${HOME}}/.zim
git clone --recursive https://github.com/Eriner/zim.git \${ZDOTDIR:-\${HOME}}/.zim

setopt EXTENDED_GLOB
for template_file ( \${ZDOTDIR:-\${HOME}}/.zim/templates/* ); do
  user_file="\${ZDOTDIR:-\${HOME}}/.\${template_file:t}"
  touch \${user_file}
  ( print -rn "\$(<\${template_file})\$(<\${user_file})" >! \${user_file} ) 2>/dev/null
  done

  # for images, check
  # https://github.com/zimfw/zimfw/wiki/Themes
  # or choice tiny and minimalist theme is 'pure'
  sed -i.bak -e "s/zprompt_theme='.*'/zprompt_theme='steeef magenta yellow green cyan magenta ! green + red ?,b yellow $'/g" ~/.zimrc
  rm .zimrc.bak
EOT
su - ${LINUX_USER} sh -c "zsh /tmp/zim-install.zsh"
rm /tmp/zim-install.zsh

set +e
rm /home/${LINUX_USER}/.bash*
rm /home/${LINUX_USER}/.profile
set -e


################################################################################
## basic applications installable via brew
##

set +e
# all the packages
brew install \
  connect \
  curl \
  diff-so-fancy \
  docker-completion \
  docker-compose-completion \
  docker-machine-completion \
  fzf \
  git \
  git-flow \
  htop \
  mc \
  mosh \
  nano \
  nmap \
  proxychains-ng \
  rbenv \
  rsync \
  ruby \
  libpcap sngrep \
  sshuttle \
  the_silver_searcher \
  tig \
  tmux \
  tmux-mem-cpu-load \
  unzip \
  util-linux \
  w3m \
  wget \
  yank

brew update
brew upgrade

apt-get -yqq purge \
  git* \
  htop* \
  mc* \
  mosh* \
  mtr* \
  nano* \
  nmap* \
  rsync* \
  sngrep* \
  tmux*

PACKAGES=( \
  ag \
  connect \
  git \
  git-flow \
  htop \
  mc \
  mosh \
  mosh-client \
  mosh-server \
  nano \
  nmap \
  proxychains4 \
  rbenv \
  rsync \
  sshuttle \
  sngrep \
  tig \
  tmux \
  tmux-mem-cpu-load \
  yank \
)
for PACKAGE in "${PACKAGES[@]}"; do
  ln -s /home/linuxbrew/.linuxbrew/bin/${PACKAGE} /usr/bin/${PACKAGE} >/dev/null 2>&1
done
set -e


################################################################################
## Rest of packages
##
# set +e
# brew install \
#   ffmpeg \
#   mplayer \
#   prettyping \
#   youtube-dl
# set -e

# Digital Ocean
# brew install doctl

################################################################################
## vim
##

## --with-client-server requires xorg
# brew install linuxbrew/xorg/xorg

## Choice one of options with vim:
## --with-lua
## or
## --with-luajit
# su - ${LINUX_USER} zsh -c 'source ~/.zshrc; brew install --with-gettext --with-lua --with-tcl vim'
# brew install vim
# set +e
# apt-get -yqq purge vim*
# ln -s /home/linuxbrew/.linuxbrew/bin/vim /usr/bin/vim >/dev/null 2>&1
# ln -s /home/linuxbrew/.linuxbrew/bin/vim /usr/bin/vi  >/dev/null 2>&1
# set -e

brew install neovim
set +e
apt-get -yqq purge vim*
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/nvim >/dev/null 2>&1
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vim  >/dev/null 2>&1
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vi   >/dev/null 2>&1
set -e


################################################################################
## Clone and bootstrap dotfiles
##
if [ ! -d "/home/${LINUX_USER}/.dotfiles" ] ; then
  git clone https://github.com/andrius/.dotfiles.git  /home/${LINUX_USER}/.dotfiles
  chown -R ${LINUX_USER}:${LINUX_USER} /home/${LINUX_USER}/.dotfiles
fi

if [ -d "/home/${LINUX_USER}/.dotfiles" ] ; then
  echo "dotfiles clonned"
fi


################################################################################
## Post-install
##
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; brew >/dev/null 2>&1; brew cleanup --prune all'
apt-get clean all
