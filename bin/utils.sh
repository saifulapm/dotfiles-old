#!/usr/bin/env bash

# Init option {{{
Color_off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue

# }}}

# success/info/error/warn {{{
msg() {
    printf '%b\n' "$1" >&2
}

success() {
    msg "${Green}[✔]${Color_off} ${1}${2}"
}

info() {
    msg "${Blue}[➭]${Color_off} ${1}${2}"
}

error() {
    msg "${Red}[✘]${Color_off} ${1}${2}"
    exit 1
}

warn () {
    msg "${Yellow}[⚠]${Color_off} ${1}${2}"
}
# }}}

# echo_with_color {{{
echo_with_color () {
    printf '%b\n' "$1$2$Color_off" >&2
}
# }}}

# install_done {{{

install_done () {
    echo_with_color ${Yellow} ""
    echo_with_color ${Yellow} "Almost done!"
    echo_with_color ${Yellow} "=============================================================================="
    echo_with_color ${Yellow} "==    Open Vim or Neovim and it will install the plugins automatically      =="
    echo_with_color ${Yellow} "=============================================================================="
    echo_with_color ${Yellow} ""
    echo_with_color ${Yellow} "That's it. Thanks for installing Saifulapm's Config. Enjoy!"
    echo_with_color ${Yellow} ""
}

###
# convienience methods for requiring installed software
###

function require_cask() {
    info "brew cask $1"
    brew cask list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        warn "brew cask install $1 $2"
        brew install $1 --cask
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    success "Installed: brew cask $1"
}

function require_brew() {
    info "brew $1 $2"
    brew list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        warn "brew install $1 $2"
        brew install $1 $2
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    success "Installed: brew $1 $2"
}

function require_node(){
    info "node -v"
    node -v
    if [[ $? != 0 ]]; then
        warn "node not found, installing via homebrew"
        brew install node
    fi
    success "Installed: node"
}

# vim:set nofoldenable foldmethod=marker:
