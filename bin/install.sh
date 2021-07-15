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
    success
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
    success
  else
    echo
    info "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/'  $HOME/.gitconfig
    sed -i 's/GITHUBUSER/'$githubuser'/'  $HOME/.gitconfig
  fi
fi


###########################################################
info "update ruby"
###########################################################

RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-libyaml-dir=`brew --prefix libyaml`"
require_brew ruby

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
    zinit install
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
  require_cask font-aurulent-sans-mono-nerd-font
  require_cask font-hack-nerd-font
  success
fi

# ###########################################################
info " Install Develop Tools"
# ###########################################################
require_brew curl
require_brew wget
require_brew ripgrep
require_brew bat
require_brew findutils
require_brew make
brew install --HEAD universal-ctags/universal-ctags/universal-ctags
require_brew tmux
require_brew grip
require_brew fd
require_brew lolcat
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

warn "link tmux conf"
ln -s  $HOME/.dotfiles/tmux/.tmux.conf $HOME/.tmux.conf
success

warn "link .rgignore"
ln -s  $HOME/.dotfiles/.rgignore $HOME/.rgignore
success

warn "link .env"
ln -s  $HOME/.dotfiles/env/.env $HOME/.env
success


warn "Install tpm"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
success "when you open tmux,you must type prefix {default: Ctrl+space } + I to install tmux plugins"

require_brew node
require_brew yarn

require_brew lua
require_brew ninja

warn "Install NPM Staff"
npm install -g create-react-app
npm install -g typescript typescript-language-server
success

info "Install Macvim"
require_cask macvim

info "Install neovim"
npm i -g bash-language-server
npm i -g intelephense
require_brew  luajit --HEAD
require_brew neovim --HEAD
info "Configruation nvim"
git clone https://github.com/saifulapm/nvim ~/.config/nvim
success
info "Install neovim Staff"
pip3 install pynvim
npm i -g neovim
pip3 install neovim-remote
success
info "Vim Staff"
ln -s $HOME/.dotfiles/config/vim ~/.vim

info "Composer Install"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
composer global require php-stubs/wordpress-globals
composer global require php-stubs/wordpress-stubs
composer global require php-stubs/woocommerce-stubs

warn "Install Shopify Staff"
brew tap shopify/shopify
require_brew themekit
require_brew shopify-cli

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
ln -s "${HOME}/.dotfiles/.simplebarrc" "${HOME}/.simplebarrc"

warn "Installing Velvet & DBngin"
# require_cask dbngin
sudo apachectl stop
sudo launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null
composer global require laravel/valet
valet install
mkdir ~/Sites
cd ~/Sites
valet park
cd ..

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
success
info "reading iterm settings"
defaults read -app iTerm > /dev/null 2>&1;
success

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
success

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

read -r -p "Do you want install PasswordManager (Pass? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_brew pass
  brew tap amar1729/formulae
  require_cask browserpass
  PREFIX='/usr/local/opt/browserpass' make hosts-chrome-user -f '/usr/local/opt/browserpass/lib/browserpass/Makefile'
  ln -s $HOME/Library/Mobile\ Documents/com~apple~CloudDocs/Passwords $HOME/.password-store
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

read -r -p "Do you want install IINA Video Player? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask iina
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

read -r -p "Do you want install wechat? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask wechat
else
  success "skipped"
fi

brew update && brew upgrade && brew cleanup

install_done
