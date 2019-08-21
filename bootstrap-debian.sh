#!/usr/bin/env bash

## Installation instructions
## If you trust in one-liner installers, then copy/paste following line (OR clone this gist, exit and execute):
##
# apt-get update && apt-get -yqq --no-install-recommends --no-install-suggests install curl ca-certificates
#
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/andrius/.dotfiles/master/bootstrap-debian.sh)"

set -x
################################################################################
## Settings
##
LINUX_USER="${LINUX_USER:-ak}"
LINUX_USER_HOME="${LINUX_USER_HOME}/home/${LINUX_USER}"
set +e
read -t 10 -p "
Creating user ${LINUX_USER} with home folder ${LINUX_USER_HOME}\nIf you want to modify, press Ctrl-C now;\nset your own LINUX_USER and LINUX_USER_HOME and rer-run script, i.e.:\n\nLINUX_USER=me LINUX_USER_HOME=/home/myhome bootstrap-debian.sh\n\nPress Enter to continue...\n" res
set -e

# TODO: set password (currently its passwordless with ssh key authentication)
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
  ca-certificates \
  curl \
  file \
  git \
  mtr-tiny \
  ncurses-bin ncurses-term libncurses5-dev \
  net-tools \
  openssl \
  rsync \
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
    --home ${LINUX_USER_HOME} \
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
else
  set -e
  echo "Docker already installed"
fi

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
  su - ${LINUX_USER} --shell `which bash` -c 'cd /home/linuxbrew/.linuxbrew && git config --local --replace-all homebrew.private true'

  echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"'      >> ${LINUX_USER_HOME}/.profile
  echo 'export MANPATH="$(brew --prefix)/share/man:$MANPATH"'    >> ${LINUX_USER_HOME}/.profile
  echo 'export INFOPATH="$(brew --prefix)/share/info:$INFOPATH"' >> ${LINUX_USER_HOME}/.profile
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

cat <<EOT > ${LINUX_USER_HOME}/.zshrc

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
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.zshrc

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
rm ${LINUX_USER_HOME}/.bash*
rm ${LINUX_USER_HOME}/.profile
set -e


################################################################################
## basic applications installable via brew
##

set +e
# all the packages
PACKAGES=( \
  connect \
  curl \
  diff-so-fancy \
  docker-completion \
  docker-compose-completion \
  docker-machine-completion \
  fzf \
  git git-flow ghi hub tig \
  httpie \
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
  luarocks \
  sshuttle \
  the_silver_searcher \
  tmux \
  tmux-mem-cpu-load \
  unzip \
  util-linux \
  w3m \
  wget \
  yank \
)
for PACKAGE in "${PACKAGES[@]}"; do
  brew install ${PACKAGE}
done

PACKAGES=( \
  ag \
  connect \
  ctags \
  git-flow \
  htop \
  mc \
  mosh-client \
  mosh-server \
  mosh \
  nano \
  nmap \
  proxychains4 \
  rbenv \
  sshuttle \
  sngrep \
  tig \
  tmux-mem-cpu-load \
  tmux \
  yamllint \
  yank \
)
for PACKAGE in "${PACKAGES[@]}"; do
  apt-get -yqq purge ${PACKAGE}*
  ln -s /home/linuxbrew/.linuxbrew/bin/${PACKAGE} /usr/bin/${PACKAGE} >/dev/null 2>&1
done
set -e


################################################################################
## Rest of packages
##
set +e

# brew install \
#   ffmpeg \
#   mplayer \
#   prettyping \
#   youtube-dl
#
# # Crystal-lang
# brew tap veelenga/tap
# brew install ameba

# # Digital Ocean
# brew install doctl

set -e
################################################################################

brew install python@2 python3 neovim
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; pip2 install --user --upgrade virtualenv'
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; pip2 install --user --upgrade pynvim'
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; pip2 install --user --upgrade neovim'
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; pip3 install --user --upgrade virtualenv'
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; pip3 install --user --upgrade pynvim'
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; pip3 install --user --upgrade neovim'
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; gem install neovim'
set +e
apt-get -yqq purge vim*
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/nvim >/dev/null 2>&1
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vim  >/dev/null 2>&1
ln -s /home/linuxbrew/.linuxbrew/bin/nvim /usr/bin/vi   >/dev/null 2>&1
set -e


################################################################################
## Clone and bootstrap dotfiles
##
if [ ! -d "${LINUX_USER_HOME}/.dotfiles" ] ; then
  git clone https://github.com/andrius/.dotfiles.git ${LINUX_USER_HOME}/.dotfiles
else
  echo ".dotfiles folder is already there, trying to update"
  cd "${LINUX_USER_HOME}/.dotfiles"
  git fetch --all
  git pull
fi
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.dotfiles

# TODO: backup
set +e
# Symlink .tmux folder
rm -rf ${LINUX_USER_HOME}/.tmux ${LINUX_USER_HOME}/.tmux.conf
ln -s ${LINUX_USER_HOME}/.dotfiles/tmux ${LINUX_USER_HOME}/.tmux
ln -s ${LINUX_USER_HOME}/.tmux/tmux.conf ${LINUX_USER_HOME}/.tmux.conf
# Create samlpe tmux user.conf
cp ${LINUX_USER_HOME}/.tmux/user.conf-sample ${LINUX_USER_HOME}/.tmux/user.conf
# Clone tmux plugins
cd ${LINUX_USER_HOME}/.dotfiles/tmux
mkdir -p plugins data
git clone https://github.com/tmux-plugins/tpm.git tpm
git clone https://github.com/tmux-plugins/tmux-resurrect tmux-resurrect
git clone https://github.com/tmux-plugins/tmux-yank tmux-yank
cd
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.tmux ${LINUX_USER_HOME}/.tmux.conf
set -e

set +e
# We use rafi nvim config with some modifications
mkdir -p ${LINUX_USER_HOME}/.config
git clone git://github.com/rafi/vim-config.git ${LINUX_USER_HOME}/.config/nvim
ln -s ${LINUX_USER_HOME}/.config/nvim ${LINUX_USER_HOME}/.vim
ln -s ${LINUX_USER_HOME}/.dotfiles/config/nvim/config/local.vim ${LINUX_USER_HOME}/.config/nvim/config/local.vim
ln -s ${LINUX_USER_HOME}/.dotfiles/config/nvim/config/local.plugins.yaml ${LINUX_USER_HOME}/.config/nvim/config/local.plugins.yaml
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/.config
su - ${LINUX_USER} zsh -c 'source ~/.zshr; cd ~/.config/nvim; ./venv.sh; make'
set -e

################################################################################
## Post-install
##
chown -R ${LINUX_USER}:${LINUX_USER} ${LINUX_USER_HOME}/
su - ${LINUX_USER} zsh -c 'source ~/.zshrc; brew >/dev/null 2>&1; brew update; brew upgrade; brew cleanup --prune all'
apt-get clean all
${LINUX_USER_HOME}/.dotfiles/bin/purge-system-logfiles


