#!/bin/bash

set -ex

LINUX_USER=ak


################################################################################
## Creating Linux user
##
#echo 'Please enter login password for new user and hit Enter:'
#read LINUX_USER_PASSWORD

apt-get update
apt-get -yqq upgrade
DEBIAN_FRONTEND=noninteractive \
apt-get -yqq --no-install-recommends --no-install-suggests -yqq install \
  build-essential \
  ca-cacert \
  ca-certificates \
  curl \
  file \
  git \
  openssl \
  sudo

adduser \
  --quiet \
  --home /home/${LINUX_USER} \
  --shell /bin/bash \
  --gecos '' \
  --disabled-password \
  --add_extra_groups \
  ${LINUX_USER}
usermod -aG sudo ${LINUX_USER}
echo "${LINUX_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${LINUX_USER}; \
chmod 0440 /etc/sudoers.d/${LINUX_USER};



################################################################################
## Installing docker
##
curl -sSL https://get.docker.com/ | sh
usermod -aG docker ${LINUX_USER}
LATEST_URL=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest`
COMPOSE_VERSION=${LATEST_URL##*/}
DOWNLOAD_URL=https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m`
curl -L ${DOWNLOAD_URL} -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


################################################################################
## Installing Linuxbrew
##
mkdir -p /home/linuxbrew/.linuxbrew
chown -R ${LINUX_USER}:${LINUX_USER} /home/linuxbrew/.linuxbrew
su - ${LINUX_USER} sh -c 'git clone https://github.com/Linuxbrew/brew.git /home/linuxbrew/.linuxbrew'

echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"'      >> /home/${LINUX_USER}/.profile
echo 'export MANPATH="$(brew --prefix)/share/man:$MANPATH"'    >> /home/${LINUX_USER}/.profile
echo 'export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"' >> /home/${LINUX_USER}/.profile

# make brew command available for root user too
echo -e "#/bin/sh\n\nsu - ${LINUX_USER} /home/linuxbrew/.linuxbrew/bin/brew \$@" > /usr/bin/brew
chmod +x /usr/bin/brew

# brew recommend to install gcc
brew install gcc


################################################################################
## zsh
##
su - ${LINUX_USER} sh -c '/home/linuxbrew/.linuxbrew/bin/brew install zsh --with-pcre --with-unicode9'
ln -s /home/linuxbrew/.linuxbrew/bin/zsh /usr/bin/zsh
grep -q -F '/usr/bin/zsh' /etc/shells || echo '/usr/bin/zsh' >> /etc/shells
chsh -s /usr/bin/zsh ${LINUX_USER}

cat <<EOT > /home/${LINUX_USER}/.zshrc


# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/bin" ] ; then
    PATH="\$HOME/bin:\$PATH"
fi

export PATH="/home/linuxbrew/.linuxbrew/bin:\$PATH"
export MANPATH="\$(brew --prefix)/share/man:\$MANPATH"
export INFOPATH="\$(brew --prefix)/share/info:\$INFOPATH"

EOT
chown -R ${LINUX_USER}:${LINUX_USER} /home/${LINUX_USER}/.zshrc

su - ${LINUX_USER} zsh -c "git clone --recursive https://github.com/Eriner/zim.git \${ZDOTDIR:-\${HOME}}/.zim"

cat <<EOT > /tmp/zim-install.zsh

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
  sed -i.bak -e "s/zprompt_theme='.*'/zprompt_theme='eriner'/g" ~/.zimrc
  rm ~/.zimrc.bak

EOT
su - ${LINUX_USER} sh -c "zsh /tmp/zim-install.zsh"
rm /tmp/zim-install.zsh

rm /home/${LINUX_USER}/.bash*
rm /home/${LINUX_USER}/.profile

################################################################################
## basic applications installable via brew
##

# applications with custom options should be installed separately
su - ${LINUX_USER} sh -c '/home/linuxbrew/.linuxbrew/bin/brew install tmux --with-utf8proc'

# all the packages
brew install \
  connect \
  curl \
  diff-so-fancy \
  feh \
  ffmpeg \
  git \
  git-flow \
  htop \
  mc \
  mdv \
  mosh \
  mplayer \
  nano \
  prettyping \
  proxychains-ng \
  rsync \
  sshuttle \
  the_silver_searcher \
  tig \
  tmux-mem-cpu-load \
  unzip \
  util-linux \
  w3m \
  wget \
  yank \
  youtube-dl

apt-get -yqq purge \
  curl* \
  git* \
  htop* \
  mc* \
  mosh* \
  nano* \
  rsync* \
  tmux* \
  zsh*

PACKAGES=( \
  ag \
  connect \
  curl \
  git \
  git-flow \
  htop \
  mc \
  mosh \
  mosh-client \
  mosh-server \
  nano \
  proxychains4 \
  rsync \
  sshuttle \
  tig \
  tmux \
  tmux-mem-cpu-load \
  yank \
)
for PACKAGE in "${PACKAGES[@]}"; do
  ln -s /home/linuxbrew/.linuxbrew/bin/${PACKAGE} /usr/bin/${PACKAGE}
done


################################################################################
## vim
##

## --with-client-server requires xorg
# brew install xorg

## Choice one of options with vim:
## --with-lua
## or
## --with-luajit
# su - ${LINUX_USER} sh -c '/home/linuxbrew/.linuxbrew/bin/brew install vim --with-client-server --with-gettext --with-lua --with-tcl'
brew install neovim

apt-get -yqq purge vim*

ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/nvim
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vim
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vi
