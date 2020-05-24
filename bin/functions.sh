is_sudo() {
  case $OSTYPE in
  darwin*)
    local group="admin"
    ;;
  *)
    local group="sudo"
    ;;
  esac

  if id -nG "${USER}" | grep -qw "${group}"; then
    return 0
  else
    return 1
  fi
}

brew_package_version() {
  local package
  local brew_prefix
  local version

  package="$1"
  brew_prefix="^$(brew --prefix)/Cellar"
  version=$(brew info "${package}" | grep "${brew_prefix}" | awk -F "${brew_prefix}/" '{print $2}' | awk -F '/| ' '{print $2}')

  # "return" a string value
  echo "${version}"
}

brew_is_head_version() {
  local version
  version=$(brew_package_version "$1")
  [[ "${version}" =~ ^HEAD ]] && return 0 || return 1
}

