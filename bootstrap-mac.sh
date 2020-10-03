#!/usr/bin/env bash

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew install gcc
brew install --HEAD mosh

PACKAGES=( \
  ansible-lint \
  autossh \
  connect \
  coreutils \
  curl \
  diff-so-fancy \
  dive \
  docker-completion \
  docker-compose-completion \
  docker-machine-completion \
  ffmpeg \
  fzf \
  ghi \
  gist \
  git \
  git-crypt \
  git-flow \
  htop \
  httpie \
  hub \
  imagemagick \
  jq \
  jsonlint \
  libpcap \
  luarocks \
  mas \
  mc \
  nano \
  nmap \
  node \
  prettyping \
  pngquant \
  proselint \
  proxychains-ng \
  python3 \
  rbenv \
  rsync \
  ruby \
  shellcheck \
  sngrep \
  speedtest-cli \
  sshuttle \
  tflint \
  the_silver_searcher \
  tidy-html5 \
  tig \
  tmux \
  tmux-mem-cpu-load \
  tree \
  unzip \
  util-linux \
  w3m \
  wget \
  wifi-password \
  write-good \
  yamllint \
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
yarn global add eslint jshint jsxhint stylelint sass-lint markdownlint-cli raml-cop
pip3 install --user vim-vint pycodestyle pyflakes flake8
brew install neovim
