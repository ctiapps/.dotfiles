#!/usr/bin/env bash

set -xe

brew install tmux
sudo apt-get -yqq purge tmux*
sudo ln -s /home/linuxbrew/.linuxbrew/bin/tmux /usr/bin/tmux

# Symlink .tmux folder
rm -rf ${HOME}/.tmux ${HOME}/.tmux.conf
ln -s ${HOME}/.dotfiles/tmux ${HOME}/.tmux
ln -s ${HOME}/.tmux/tmux.conf ${HOME}/.tmux.conf

# Create samlpe tmux user.conf
cp ${HOME}/.tmux/user.conf-sample ${HOME}/.tmux/user.conf

# Clone tmux plugins
cd ${HOME}/.dotfiles/tmux
mkdir -p plugins data
cd plugins
git clone https://github.com/tmux-plugins/tpm.git tpm
git clone https://github.com/tmux-plugins/tmux-resurrect tmux-resurrect
git clone https://github.com/tmux-plugins/tmux-yank tmux-yank

# Linux only (pbcopy), TODO: add system detection
git clone https://github.com/skaji/remote-pbcopy-iterm2.git pbcopy
chmod +x pbcopy/pbcopy
ln -s ${HOME}/.dotfiles/tmux/plugins/pbcopy/pbcopy ${HOME}/.dotfiles/bin/pbcopy
