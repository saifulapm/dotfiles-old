#!/usr/bin/env bash

###
# format print
###

# Colors
ESC_SEQ="\033["
COL_RESET=$ESC_SEQ"0m"
COL_RED=$ESC_SEQ"0;31m"
COL_GREEN=$ESC_SEQ"0;32m"
COL_YELLOW=$ESC_SEQ"1;33m"
COL_BLUE=$ESC_SEQ"0;34m"
COL_MAGENTA=$ESC_SEQ"0;35m"
COL_CYAN=$ESC_SEQ"0;36m"

function ok() {
    printf  "${COL_GREEN}[ok]${COL_RESET} "$1
}

function bot() {
    printf  "\n${COL_GREEN}[._.]${COL_RESET} - "$1
}

function running() {
    printf  "${COL_YELLOW} ⇒ ${COL_RESET}"$1": "
}

function action() {
    printf  "\n${COL_YELLOW}[action]:${COL_RESET}\n ⇒ $1..."
}

function warn() {
    printf  "${COL_YELLOW}[warning]${COL_RESET} "$1
}

function error() {
    printf  "${COL_RED}[error]${COL_RESET} "$1
}

###
# convienience methods for requiring installed software
###

function require_cask() {
    running "brew cask $1"
    brew cask list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew cask install $1 $2"
        brew install $1 --cask
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

function require_brew() {
    running "brew $1 $2"
    brew list $1 > /dev/null 2>&1 | true
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        action "brew install $1 $2"
        brew install $1 $2
        if [[ $? != 0 ]]; then
            error "failed to install $1! aborting..."
            # exit -1
        fi
    fi
    ok
}

function require_node(){
    running "node -v"
    node -v
    if [[ $? != 0 ]]; then
        action "node not found, installing via homebrew"
        brew install node
    fi
    ok
}

function require_npm() {
    sourceNVM
    nvm use stable
    running "npm $*"
    npm list -g --depth 0 | grep $1@ > /dev/null
    if [[ $? != 0 ]]; then
        action "npm install -g $*"
        npm install -g $@
    fi
    ok
}
