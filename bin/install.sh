#!/usr/bin/env bash

# include my library helpers for colorized echo and require_brew, etc
source ./bin/utils.sh

defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

# ###########################################################
# Install non-brew various tools (PRE-BREW Installs)
# ###########################################################
info "ensuring build/install tools are available"
if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    success ' XCode Command Line Tools Installed'

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license
    success 'Agree with the XCode Command Line Tools licence'

fi

# ###########################################################
# install homebrew (CLI Packages)
# ###########################################################

info "checking homebrew..."
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  warn "installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ $? != 0 ]]; then
    error "unable to install homebrew, script $0 abort!"
    exit 2
  fi
else
  success
  info "Homebrew"
  read -r -p "run brew update && upgrade? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    warn "updating homebrew..."
    brew update
    success "homebrew updated"
    warn "upgrading brew packages..."
    brew upgrade
    success "brews upgraded"
  else
    success "skipped brew package upgrades."
  fi
fi

# Just to avoid a potential bug
mkdir -p ~/Library/Caches/Homebrew/Formula
brew doctor

###########################################################
# Git Config
###########################################################

# skip those GUI clients, git command-line all the way
require_brew git

info "success, now I am going to update the .gitconfig for your user info:"

gitfile="$HOME/.gitconfig"
info "link .gitconfig"
if [ ! -f "gitfile" ]; then
  read -r -p "Seems like your gitconfig file exist,do you want delete it? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    rm -rf $HOME/.gitconfig
    warn "cp /git/.gitconfig ~/.gitconfig"
    sudo cp $HOME/.dotfiles/git/.gitconfig  $HOME/.gitconfig
    ln -s $HOME/.dotfiles/git/.gitignore  $HOME/.gitignore
    success "link .gitconfig"
  else
    success "skipped"
  fi
fi
grep 'user = GITHUBUSER'  $HOME/.gitconfig > /dev/null 2>&1
if [[ $? = 0 ]]; then
    read -r -p "What is your git username? " githubuser

  fullname=`osascript -e "long user name of (system info)"`

  if [[ -n "$fullname" ]];then
    lastname=$(echo $fullname | awk '{print $2}');
    firstname=$(echo $fullname | awk '{print $1}');
  fi

  if [[ -z $lastname ]]; then
    lastname=`dscl . -read /Users/$(whoami) | grep LastName | sed "s/LastName: //"`
  fi
  if [[ -z $firstname ]]; then
    firstname=`dscl . -read /Users/$(whoami) | grep FirstName | sed "s/FirstName: //"`
  fi
  email=`dscl . -read /Users/$(whoami)  | grep EMailAddress | sed "s/EMailAddress: //"`

  if [[ ! "$firstname" ]]; then
    response='n'
  else
    printf  "I see that your full name is $COL_YELLOW$firstname $lastname$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]]; then
    read -r -p "What is your first name? " firstname
    read -r -p "What is your last name? " lastname
  fi
  fullname="$firstname $lastname"

  info "Great $fullname, "

  if [[ ! $email ]]; then
    response='n'
  else
    printf  "The best I can make out, your email address is $COL_YELLOW$email$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]]; then
    read -r -p "What is your email? " email
    if [[ ! $email ]];then
      error "you must provide an email to configure .gitconfig"
      exit 1
    fi
  fi


  info "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

  # test if gnu-sed or MacOS sed

  sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./git/.gitconfig > /dev/null 2>&1 | true
  if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo
    info "looks like you are using MacOS sed rather than gnu-sed, accommodating"
    sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/"  $HOME/.gitconfig
    sed -i '' 's/GITHUBEMAIL/'$email'/'  $HOME/.gitconfig
    sed -i '' 's/GITHUBUSER/'$githubuser'/'  $HOME/.gitconfig
    success ".gticonfig updated"
  else
    echo
    info "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/'  $HOME/.gitconfig
    sed -i 's/GITHUBUSER/'$githubuser'/'  $HOME/.gitconfig
  fi
fi

# ###########################################################
info "zsh setup"
# ###########################################################

require_brew zsh

# symslink zsh config
ZSHRC="$HOME/.zshrc"
info "Configuring zsh"
if [ ! -f "ZSHRC" ]; then
  read -r -p "Seems like your zshrc file exist,do you want delete it? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    rm -rf $HOME/.zshrc
    rm -rf $HOME/.zshenv
    warn "link zsh/.zshrc and zsh/.zshenv"
    ln -s  $HOME/.dotfiles/zsh/.zshenv $HOME/.zshenv
    ln -s  $HOME/.dotfiles/zsh/.zshrc $HOME/.zshrc
    ln -s  $HOME/.dotfiles/zsh/.p10k-evilball.zsh $HOME/.p10k-evilball.zsh
    if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
      print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
      command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
      command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f" || \
        print -P "%F{160}▓▒░ The clone has failed.%f"
    fi
    source $HOME/.zshrc
    zinit install
  else
    success "skipped"
  fi
fi

###########################################################
info "update ruby"
###########################################################
require_brew rbenv
require_brew ruby-build
source $HOME/.zshrc
rbenv install 3.0.2
rbenv global 3.0.2
gem install rails -v 6.1.4.1
rbenv rehash
sudo installer -pkg
/Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
success "ruby and rails installed"

# ###########################################################
info "Install fonts"
# ###########################################################
read -r -p "Install fonts? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  info "installing fonts"
  # need fontconfig to install/build fonts
  require_brew fontconfig
  sh ./fonts/install.sh
  brew tap homebrew/cask-fonts
  require_cask font-hack-nerd-font
  success "Fonts installed"
fi

# ###########################################################
info " Install Develop Tools"
# ###########################################################
require_brew curl
require_brew wget
require_brew gh
require_brew ripgrep
require_brew bat
require_brew findutils
require_brew make
brew install --HEAD universal-ctags/universal-ctags/universal-ctags
require_brew tmux
require_brew grip
require_brew fd
# require_brew lolcat
require_brew php
require_brew openssl
require_brew mariadb
# require_brew httpd
require_brew tree
require_brew fzf
require_brew jq
/usr/local/opt/fzf/install
brew install jesseduffield/lazygit/lazygit
require_brew lsd
require_brew hub
require_brew z

warn "link tmux conf"
ln -s  $HOME/.dotfiles/tmux/.tmux.conf $HOME/.tmux.conf
success "tmux conf linked"

warn "link .rgignore"
ln -s  $HOME/.dotfiles/.rgignore $HOME/.rgignore
success "rgignore linked"

warn "link .env"
ln -s  $HOME/.dotfiles/env/.env $HOME/.env
success "env linked"


warn "Install tpm"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
success "when you open tmux,you must type prefix {default: Ctrl+space } + I to install tmux plugins"

require_brew node
require_brew yarn

require_brew lua
require_brew ninja

# warn "Install NPM Staff"
# npm install -g create-react-app
# npm install -g typescript typescript-language-server
# success

info "Install vim"
require_brew vim

require_brew rust

info "Install neovim"
require_brew luajit
require_brew neovim
# info "Configruation nvim"
# git clone https://github.com/saifulapm/nvim ~/.config/nvim
# success
info "Install neovim Staff"
pip3 install pynvim
npm i -g neovim
npm install -g intelephense
# npm i -g write-good
# require_brew shellcheck
npm i -g prettier
# npm install -g markdownlint-cli
# npm i -g markdownlint
pip3 install neovim-remote
cargo install stylua
require_brew php-cs-fixer
success "nvim installed"
# info "Vim Staff"
# ln -s $HOME/.dotfiles/config/vim ~/.vim

info "Composer Install"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
success "composer installed"

warn "Install Shopify Staff"
brew tap shopify/shopify
require_brew themekit
require_brew shopify-cli
require_brew theme-check

warn "Installing Velvet & DBngin"
# require_cask dbngin
sudo apachectl stop
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
composer global require laravel/valet
# valet install
mkdir ~/Sites
# cd ~/Sites
# valet park
# cd ..

warn "PHP IMAP"
brew tap kabel/php-ext
require_brew php-imap

# ###########################################################
info " Install Gui Applications"
# ###########################################################

read -r -p "Do you want install kitty? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask kitty
else
  success "skipped"
fi
info "Configuration kitty settings"
ln -s $HOME/.dotfiles/config/kitty  $HOME/.config/kitty
success "kitty settings configured"

read -r -p "Do you want install alacritty? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask alacritty

  info "setup Terminal Info"
  git clone https://github.com/alacritty/alacritty.git
  cd alacritty
  sudo tic -xe alacritty,alacritty-direct extra/alacritty.Info
  cd .. && rm -rf alacritty
else
  success "skipped"
fi

info "Configuration alacritty settings"
ln -s $HOME/.dotfiles/config/alacritty  $HOME/.config/alacritty
success "alacritty settings configured"

read -r -p "Do you want install google-chrome? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask google-chrome
else
  success "skipped"
fi

read -r -p "Do you want install zoom? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask zoom
else
  success "skipped"
fi

read -r -p "Do you want install voov-meeting? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask voov-meeting
else
  success "skipped"
fi

read -r -p "Do you want install keka? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask keka
else
  success "skipped"
fi

read -r -p "Do you want install KeepYouAwake? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask keepingyouawake
else
  success "skipped"
fi

read -r -p "Do you want install HTTP and GraphQL Client(insomnia)? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask insomnia
else
  success "skipped"
fi

read -r -p "Do you want install VPN (tunnelblick)? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask tunnelblick
else
  success "skipped"
fi

read -r -p "Do you want install whatsapp? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask whatsapp
else
  success "skipped"
fi


read -r -p "Do you want install vlc? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask vlc
else
  success "skipped"
fi

read -r -p "Do you want install alfred? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask alfred
else
  success "skipped"
fi


read -r -p "Do you want install vscode? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask visual-studio-code
else
  success "skipped"
fi

read -r -p "Do you want install rectangle? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask rectangle
else
  success "skipped"
fi

read -r -p "Do you want install Yabai? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  warn "Install yabai and skhd"
  brew install koekeishiya/formulae/yabai
  brew install koekeishiya/formulae/skhd
  sudo yabai --install-sa
  ln -s "${HOME}/.dotfiles/yabai/yabairc" "${HOME}/.yabairc"
  ln -s "${HOME}/.dotfiles/yabai/skhdrc" "${HOME}/.skhdrc"
  brew services start skhd
  brew services start koekeishiya/formulae/yabai
  sudo mv ${HOME}/.dotfiles/yabai/yabai /private/etc/sudoers.d/
  sudo yabai --load-sa
  yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
  warn "Installing Simple Bar"
  require_cask ubersicht
  git clone https://github.com/Jean-Tinland/simple-bar $HOME/Library/Application\ Support/Übersicht/widgets/simple-bar
  # ln -s "${HOME}/.dotfiles/.simplebarrc" "${HOME}/.simplebarrc"
else
  success "skipped"
fi

read -r -p "Do you want install wechat? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask wechat
else
  success "skipped"
fi

brew update && brew upgrade && brew cleanup

install_done
