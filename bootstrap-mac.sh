#!/usr/bin/env bash

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew install gcc
brew install --HEAD mosh

PACKAGES=( \
  autossh \
  connect \
  coreutils \
  curl \
  diff-so-fancy \
  docker-completion \
  docker-compose-completion \
  docker-machine-completion \
  ffmpeg \
  fzf \
  git git-flow git-crypt gist ghi hub tig \
  httpie \
  htop \
  imagemagick \
  mc \
  nano \
  nmap \
  node \
  pngquant \
  proxychains-ng \
  python3 \
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
  yarn \
  z \
  zip \
)
for PACKAGE in "${PACKAGES[@]}"; do
  brew install ${PACKAGE}
done

# cd /tmp
# git clone -b "stable" https://github.com/deajan/osync
# cd osync
# sudo bash install.sh
# osync.sh
# cd ..
# rm -rf osync

brew install --HEAD universal-ctags/universal-ctags/universal-ctags
brew install shellcheck jsonlint yamllint tflint ansible-lint tidy-html5 proselint write-good
yarn global add eslint jshint jsxhint stylelint sass-lint markdownlint-cli raml-cop
pip3 install --user vim-vint pycodestyle pyflakes flake8
brew install neovim
