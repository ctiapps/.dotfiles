#!/usr/bin/env bash
# vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab filetype=sh fileencoding=utf-8 :
set -ueox pipefail

### Installation instructions
###
### If you trust in one-liner installers, then copy/paste following line:
###
### ```shell
### apt-get update && apt-get -yqq --no-install-recommends --no-install-suggests install curl ca-certificates && bash -c "$(curl -fsSL https://raw.githubusercontent.com/andrius/.dotfiles/master/bootstrap-debian-basic.sh)"
### ```
###
### or clone this repository, review and run bootstrap script:
### ```shell
### apt-get update && apt-get -yqq --no-install-recommends --no-install-suggests install git ca-certificates && git clone https://github.com/andrius/.dotfiles.git && cd .dotfiles"
### ```

confirm_data() {
    SYSTEM_USER="${SYSTEM_USER:-ak}"
    SYSTEM_USER_HOME="${SYSTEM_USER_HOME:-/home/${SYSTEM_USER}}"

    set +e
    read -r -t 10 -p "
    Creating user ${SYSTEM_USER} with home folder ${SYSTEM_USER_HOME}\nIf you want to modify, press Ctrl-C now;\nset your own SYSTEM_USER and SYSTEM_USER_HOME and rer-run script, i.e.:\n\nSYSTEM_USER=me SYSTEM_USER_HOME=/home/myhome bootstrap-debian.sh\n\nPress Enter to continue...\n" res
    set -e
}


upgrade_system() {
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -yqq --no-install-recommends --no-install-suggests upgrade
    DEBIAN_FRONTEND=noninteractive apt-get -yqq autoremove
}


install_packages() {
    DEBIAN_FRONTEND=noninteractive \
    apt-get -yqq --no-install-recommends --no-install-suggests install \
        build-essential \
        ca-certificates \
        curl \
        file \
        git \
        htop \
        mc \
        mtr-tiny \
        nano \
        net-tools \
        nmap \
        openssh-server \
        openssl \
        proxychains4 \
        psmisc \
        rsync \
        sshuttle \
        sudo \
        tig \
        unzip \
        w3m \
        wget \
        zsh
}


setup_locales() {
    DEBIAN_FRONTEND=noninteractive \
    apt-get -yqq --no-install-recommends --no-install-suggests install \
        locales

    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
    locale-gen
}


confirm_reboot() {
    set +e
    read -r -t 10 -p "Type 'reboot' and hit ENTER, if you want to reboot after upgrade/install, or just press ENTER to continue installation\n" res
    if [[ "$res" != "" ]]; then
        echo "Rebooting, you'll need to run this script again after that..."
        reboot
    fi
    set -e
}


create_user() {
    set +e
    if getent passwd "${SYSTEM_USER}" >/dev/null 2>&1; then
        echo "User ${SYSTEM_USER} already exists"
    else
        set -e
        echo "Creating user ${SYSTEM_USER} with home-dir ${SYSTEM_USER_HOME}"
        adduser \
            --quiet \
            --home "${SYSTEM_USER_HOME}" \
            --shell "$(which zsh)" \
            --gecos "" \
            --disabled-password \
            --add_extra_groups \
            "${SYSTEM_USER}"
    fi
    set -e

    usermod -aG sudo "${SYSTEM_USER}"
    echo "${SYSTEM_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${SYSTEM_USER}"
    chmod 0440 "/etc/sudoers.d/${SYSTEM_USER}"
}


install_docker() {
    set +e
    if docker -v > /dev/null 2>&1; then
        echo "Docker is already installed"
    else
        set -e
        curl -sSL https://get.docker.com/ | sh
        usermod -aG docker "${SYSTEM_USER}"
    fi

    set +e
    if docker-compose -v > /dev/null 2>&1; then
        echo "docker-compose is already installed"
    else
        set -e
        LATEST_URL="$(curl -Ls -o /dev/null -w '%{url_effective}' https://github.com/docker/compose/releases/latest)"
        COMPOSE_VERSION="${LATEST_URL##*/}"
        DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
        curl -L "${DOWNLOAD_URL}" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        set +e
        docker-compose -v > /dev/null 2>&1 || echo "There is issues with docker-compose, please check!"
        set -e
    fi
}


install_brew() {
    if [ ! -d "${SYSTEM_USER_HOME}/.linuxbrew" ] ; then
        git clone --depth 1 https://github.com/Homebrew/brew.git "${SYSTEM_USER_HOME}/.linuxbrew"
        mkdir -p /home/linuxbrew
        chown -R "${SYSTEM_USER}:${SYSTEM_USER}" /home/linuxbrew
        ln -s "${SYSTEM_USER_HOME}"/.linuxbrew /home/linuxbrew/.linuxbrew
    fi
    cd "${SYSTEM_USER_HOME}/.linuxbrew"
    git config --local --replace-all homebrew.private true
    cat << '    EOT' | sed -e 's/^    //' > "${SYSTEM_USER_HOME}/.zshrc"
    # # Uncomment if there would be issues with TERM
    # case $TERM in screen-256*) TERM=screen;; esac
    # case $TERM in xterm-256*)  TERM=screen;; esac
    # case $TERM in tmux-256*)   TERM=screen;; esac

    # set PATH so it includes user's private bin if it exists
    [ -d "${HOME}/bin" ] && PATH="${HOME}/bin:${PATH}"
    [ -d "${HOME}/.dotfiles/bin" ] && PATH="${HOME}/.dotfiles/bin:${PATH}"
    [ -d "${HOME}/.dotfiles/local/bin" ] && PATH="${HOME}/.dotfiles/local/bin:${PATH}"

    if [ -d "${HOME}/.linuxbrew/bin" ]; then
        export PATH="${HOME}/.linuxbrew/bin:${PATH}"
        export MANPATH="$(brew --prefix)/share/man:${MANPATH}"
        export INFOPATH="$(brew --prefix)/share/info:${INFOPATH}"
    fi

    # Remove duplicate entries from PATH:
    PATH="$(echo "${PATH}" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')"
    EOT
    chown -R "${SYSTEM_USER}:${SYSTEM_USER}" "${SYSTEM_USER_HOME}"
    set +e
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew >/dev/null 2>&1"
    set -e
}


# Install brew zsh (and replace system version)
install_zsh() {
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew install --quiet zsh"
    set +e
    DEBIAN_FRONTEND=noninteractive apt-get -yqq purge zsh*
    rm -rf /usr/bin/zsh
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/zsh /usr/bin/zsh
    grep -q -F "/usr/bin/zsh" /etc/shells || echo "/usr/bin/zsh" >> /etc/shells
    chsh -s /usr/bin/zsh "${SYSTEM_USER}"
    set -e
    su - "${SYSTEM_USER}" zsh -c "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh"
}


install_mosh() {
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew install --quiet --HEAD mosh"
    set +e
    DEBIAN_FRONTEND=noninteractive apt-get -yqq purge mosh*
    rm -rf /usr/bin/mosh*
    set -e
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/mosh-server /usr/bin/mosh-server
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/mosh-client /usr/bin/mosh-client
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/mosh /usr/bin/mosh
}


install_dotfiles() {
    if [ ! -d "${SYSTEM_USER_HOME}/.dotfiles" ] ; then
        git clone https://github.com/andrius/.dotfiles.git "${SYSTEM_USER_HOME}/.dotfiles"
    else
        echo ".dotfiles folder is already there"
    fi
    cd "${SYSTEM_USER_HOME}/.dotfiles"
    git fetch --all
    git pull

    cd "${SYSTEM_USER_HOME}/.dotfiles"
    mkdir -p local
    chown -R "${SYSTEM_USER}":"${SYSTEM_USER}" "${SYSTEM_USER_HOME}/.dotfiles"
}

install_tmux() {
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew install --quiet tmux"
    set +e
    DEBIAN_FRONTEND=noninteractive apt-get -yqq purge tmux*
    rm -rf /usr/bin/tmux
    rm -rf "${SYSTEM_USER_HOME}"/.tmux \
           "${SYSTEM_USER_HOME}"/.tmux.conf
    set -e
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/tmux /usr/bin/tmux
    ln -s "${SYSTEM_USER_HOME}"/.dotfiles/tmux "${SYSTEM_USER_HOME}"/.tmux
    ln -s "${SYSTEM_USER_HOME}"/.tmux/tmux.conf "${SYSTEM_USER_HOME}"/.tmux.conf
    # Create samlpe tmux user.conf
    cp "${SYSTEM_USER_HOME}"/.tmux/user.conf-sample "${SYSTEM_USER_HOME}"/.tmux/user.conf
    mkdir -p "${SYSTEM_USER_HOME}"/.tmux/plugins \
             "${SYSTEM_USER_HOME}"/.tmux/data
    if [ ! -d "${SYSTEM_USER_HOME}"/.tmux/plugins/tpm ] ; then
        git clone --depth 1 https://github.com/tmux-plugins/tpm "${SYSTEM_USER_HOME}"/.tmux/plugins/tpm
    fi
    chown -R "${SYSTEM_USER}":"${SYSTEM_USER}" "${SYSTEM_USER_HOME}"/.tmux
    chown -R "${SYSTEM_USER}":"${SYSTEM_USER}" "${SYSTEM_USER_HOME}"/.tmux.conf
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc && cd \"${SYSTEM_USER_HOME}\"/.tmux/plugins/tpm/bin && ./install_plugins && cd && tmux new-session -d -s tmp sleep 180s"
}


install_apps() {
    PACKAGES=( \
        connect \
        diff-so-fancy \
        fzf \
        sngrep \
        the_silver_searcher \
        util-linux \
    )
    set +e
    for PACKAGE in "${PACKAGES[@]}"; do
        su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew install --quiet ${PACKAGE}"
    done
    set -e

    PACKAGES=( \
        ag \
        connect \
        sngrep \
    )
    set +e
    for PACKAGE in "${PACKAGES[@]}"; do
        apt-get -yqq purge "${PACKAGE}"*
        if [ -f "${SYSTEM_USER_HOME}/.linuxbrew/bin/${PACKAGE}" ]; then
            ln -s "${SYSTEM_USER_HOME}/.linuxbrew/bin/${PACKAGE}" "/usr/bin/${PACKAGE}"
        fi
    done
    set -e

    ################################################################################
    ## Rest of packages
    ##
    # brew install \
    #   mplayer \
    #   prettyping \
    #
    # # Crystal-lang
    # brew tap veelenga/tap
    # brew install ameba

    # # Digital Ocean
    # brew install doctl
}


install_nvim() {
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew install --quiet neovim"
    set +e
    DEBIAN_FRONTEND=noninteractive apt-get -yqq purge vim* neovim*
    rm -rf /usr/bin/vim
    rm -rf /usr/bin/nvim
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/nvim /usr/bin/nvim
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/nvim /usr/bin/mvim
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/nvim /usr/bin/vim
    ln -s "${SYSTEM_USER_HOME}"/.linuxbrew/bin/nvim /usr/bin/vi
    set -e
}


post_install(){
    su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew >/dev/null 2>&1; brew update; brew upgrade"
}


cleanup() {
    set +e
    apt-get -yqq clean all
    # su - "${SYSTEM_USER}" zsh -c "source ~/.zshrc; brew cleanup --prune all >/dev/null 2>&1"
    "${SYSTEM_USER_HOME}"/.dotfiles/bin/purge-system-logfiles
    rm -rf "${SYSTEM_USER_HOME}"/.linuxbrew/Library/Taps/homebrew/homebrew-core
    rm -rf /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/*
    set -e
}


confirm_data
upgrade_system
setup_locales
install_packages
confirm_reboot
create_user
install_docker
install_brew
install_zsh
install_mosh
install_dotfiles
install_tmux
install_apps
install_nvim
post_install
cleanup

echo "Success!"
