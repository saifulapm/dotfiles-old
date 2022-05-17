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
    rm -rf $HOME/.oh-my-zsh
    warn "Installing Oh My Zsh"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    rm -rf $HOME/.zshrc
    rm -rf $HOME/.zshenv
    warn "link zsh/.zshrc and zsh/others"
    ln -s  $HOME/.dotfiles/zsh/.zshrc $HOME/.zshrc
    source $HOME/.zshrc
  else
    success "skipped"
  fi
fi

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
  require_cask font-jetbrains-mono
  require_cask font-jetbrains-mono-nerd-font
  success "Fonts installed"
fi

# ###########################################################
info " Install Develop Tools"
# ###########################################################
require_brew coreutils
require_brew curl
require_brew wget
require_brew gh
require_brew ripgrep
require_brew bat
require_brew findutils
require_brew make
require_brew tmux
require_brew ffmpeg
require_brew httpie
require_brew mackup
require_brew mas
require_brew fd
# Spatie Medialibrary
require_brew jpegoptim
require_brew optipng
require_brew pngquant
require_brew svgo
require_brew gifsicle
require_brew lua
require_brew ninja
require_brew vim
require_brew rust
require_brew php
require_brew openssl
require_brew mariadb
require_brew composer
require_brew tree
require_brew imagemagick
require_brew meilisearch
require_brew nginx
require_brew node
require_brew redis
require_brew yarn
require_brew luajit
require_brew neovim
require_brew php-cs-fixer
require_brew jq
require_brew fzf
$(brew --prefix)/opt/fzf/install
brew install jesseduffield/lazygit/lazygit
require_brew lsd
require_brew hub
require_brew z
success "Brew Packages installed"

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

info "Install neovim"
git clone https://github.com/saifulapm/nvim ~/.config/nvim
# success
info "Install neovim Staff"
pip3 install pynvim
npm i -g neovim
npm i -g prettier
pip3 install neovim-remote
cargo install stylua
success "nvim installed"
info "Vim Staff"
ln -s $HOME/.dotfiles/config/vim ~/.vim
success "Vim and Neovim Done"

warn "Install Shopify Staff"
brew tap shopify/shopify
require_brew themekit
require_brew shopify-cli
success "Shopify Staff Done"

# Install PHP extensions with PECL
info "Install PHP extensions with PECL"
pecl install imagick redis swoole

warn "PHP IMAP extension"
brew tap kabel/php-ext
require_brew php-imap
success "PHP extension Done"

info "Installing Composer Packages"
# Install global Composer packages
/usr/local/bin/composer global require laravel/installer laravel/valet beyondcode/expose spatie/global-ray spatie/visit
success "Composer Packages Installed"

info "Creating Directories"
# Create a Sites directory
mkdir $HOME/Sites
# Create sites subdirectories
mkdir $HOME/Sites/blade-ui-kit
mkdir $HOME/Sites/laravel
success "Directories created"

info "Setting Up Valet & Expose"
# Install Laravel Valet
$HOME/.composer/vendor/bin/valet install
# Install Global Ray
$HOME/.composer/vendor/bin/global-ray install
success "Valet & Expose Installed"

# Symlink the Mackup config file to the home directory
ln -s $HOME/.dotfiles/.mackup.cfg $HOME/.mackup.cfg

# ###########################################################
info " Install Gui Applications"
# ###########################################################

read -r -p "Do you want install kitty? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask kitty
  info "Configuration kitty settings"
  ln -s $HOME/.dotfiles/config/kitty  $HOME/.config/kitty
  success "kitty settings configured"
else
  success "skipped"
fi

read -r -p "Do you want install alacritty? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask alacritty

  info "setup Terminal Info"
  git clone https://github.com/alacritty/alacritty.git
  cd alacritty
  sudo tic -xe alacritty,alacritty-direct extra/alacritty.Info
  cd .. && rm -rf alacritty

  info "Configuration alacritty settings"
  ln -s $HOME/.dotfiles/config/alacritty  $HOME/.config/alacritty
  success "alacritty settings configured"
else
  success "skipped"
fi


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

read -r -p "Do you want install dbngin? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask dbngin
else
  success "skipped"
fi

read -r -p "Do you want install firefox? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask firefox
else
  success "skipped"
fi

read -r -p "Do you want install helo (Email tester and debugger)? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask helo
else
  success "skipped"
fi

read -r -p "Do you want install imageoptim? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask imageoptim
else
  success "skipped"
fi

read -r -p "Do you want install phpmon? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask phpmon
else
  success "skipped"
fi

read -r -p "Do you want install phpstorm? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask phpstorm
else
  success "skipped"
fi

read -r -p "Do you want install ray? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask ray
else
  success "skipped"
fi

read -r -p "Do you want install screenflow? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask screenflow
else
  success "skipped"
fi

read -r -p "Do you want install tableplus? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask tableplus
else
  success "skipped"
fi

read -r -p "Do you want install tinkerwell? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask tinkerwell
else
  success "skipped"
fi

read -r -p "Do you want install transmit? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask transmit
else
  success "skipped"
fi

read -r -p "Do you want install qlmarkdown? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask qlmarkdown
else
  success "skipped"
fi

read -r -p "Do you want install quicklook-json? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask quicklook-json
else
  success "skipped"
fi

read -r -p "Do you want install pastebot? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask pastebot
else
  success "skipped"
fi

info "Installing Mac App Store Apps"
# Mac App Store
# mas 'Byword', id: 420212497
info "Installing Giphy Capture"
mas 'Giphy Capture', id: 668208984
success "Done Giphy Capture"
info "Installing Keynote"
mas 'Keynote', id: 409183694
success "Done Keynote"
info "Installing Pages"
mas 'Pages', id: 409201541
success "Done Pages"
info "Installing Numbers"
mas 'Numbers', id: 409203825
success "Done Numbers"
info "Installing Spark"
mas 'Spark', id: 1176895641
success "Done Spark"
# mas 'Things', id: 904280696

brew update && brew upgrade && brew cleanup

install_done
