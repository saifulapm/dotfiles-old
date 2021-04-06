#!/usr/bin/env bash

# include my library helpers for colorized echo and require_brew, etc
source ./bin/utils.sh

defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

# ###########################################################
# Install non-brew various tools (PRE-BREW Installs)
# ###########################################################
bot "ensuring build/install tools are available"
if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    ok ' XCode Command Line Tools Installed'

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license
    ok 'Agree with the XCode Command Line Tools licence'

fi

# ###########################################################
# install homebrew (CLI Packages)
# ###########################################################

running "checking homebrew..."
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ $? != 0 ]]; then
    error "unable to install homebrew, script $0 abort!"
    exit 2
  fi
else
  ok
  bot "Homebrew"
  read -r -p "run brew update && upgrade? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    action "updating homebrew..."
    brew update
    ok "homebrew updated"
    action "upgrading brew packages..."
    brew upgrade
    ok "brews upgraded"
  else
    ok "skipped brew package upgrades."
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

bot "OK, now I am going to update the .gitconfig for your user info:"

gitfile="$HOME/.gitconfig"
running "link .gitconfig"
if [ ! -f "gitfile" ]; then
  read -r -p "Seems like your gitconfig file exist,do you want delete it? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    rm -rf $HOME/.gitconfig
    action "cp /git/.gitconfig ~/.gitconfig"
    sudo cp $HOME/.dotfiles/git/.gitconfig  $HOME/.gitconfig
    ln -s $HOME/.dotfiles/git/.gitignore  $HOME/.gitignore
    ok
  else
    ok "skipped"
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

  bot "Great $fullname, "

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


  running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

  # test if gnu-sed or MacOS sed

  sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./git/.gitconfig > /dev/null 2>&1 | true
  if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo
    running "looks like you are using MacOS sed rather than gnu-sed, accommodating"
    sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/"  $HOME/.gitconfig
    sed -i '' 's/GITHUBEMAIL/'$email'/'  $HOME/.gitconfig
    sed -i '' 's/GITHUBUSER/'$githubuser'/'  $HOME/.gitconfig
    ok
  else
    echo
    bot "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/'  $HOME/.gitconfig
    sed -i 's/GITHUBUSER/'$githubuser'/'  $HOME/.gitconfig
  fi
fi


###########################################################
bot "update ruby"
###########################################################

RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-libyaml-dir=`brew --prefix libyaml`"
require_brew ruby

# ###########################################################
bot "zsh setup"
# ###########################################################

require_brew zsh

# symslink zsh config
ZSHRC="$HOME/.zshrc"
running "Configuring zsh"
if [ ! -f "ZSHRC" ]; then
  read -r -p "Seems like your zshrc file exist,do you want delete it? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    rm -rf $HOME/.zshrc
    rm -rf $HOME/.zshenv
    action "link zsh/.zshrc and zsh/.zshenv"
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
    ok "skipped"
  fi
fi

# ###########################################################
bot "Install fonts"
# ###########################################################
read -r -p "Install fonts? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  bot "installing fonts"
  # need fontconfig to install/build fonts
  require_brew fontconfig
  sh ./fonts/install.sh
  brew tap homebrew/cask-fonts
  require_cask font-aurulent-sans-mono-nerd-font
  require_cask font-hack-nerd-font
  ok
fi

# ###########################################################
bot " Install Develop Tools"
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
require_brew httpd
brew services start httpd
require_brew tree
require_brew fzf
/usr/local/opt/fzf/install
brew install jesseduffield/lazygit/lazygit
require_brew lsd

action "link tmux conf"
ln -s  $HOME/.dotfiles/tmux/.tmux.conf $HOME/.tmux.conf
ok

action "link .rgignore"
ln -s  $HOME/.dotfiles/.rgignore $HOME/.rgignore
ok

action "link .env"
ln -s  $HOME/.dotfiles/env/.env $HOME/.env
ok


action "Install tpm"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ok "when you open tmux,you must type prefix {default: Ctrl+space } + I to install tmux plugins"

require_brew node
require_brew yarn

require_brew lua
require_brew ninja

action "Install NPM Staff"
npm install -g create-react-app
npm install -g typescript typescript-language-server
ok

bot "Install neovim"
npm i -g bash-language-server
npm i -g intelephense
require_brew  luajit --HEAD
require_brew neovim --HEAD
running "Configruation nvim"
git clone https://github.com/saifulapm/nvim ~/.config/nvim
ok
running "Install neovim Staff"
pip3 install pynvim
npm i -g neovim
pip3 install neovim-remote
ok
running "Install vim plugins"
cd ~/.config/nvim
make install
cd -

bot "Composer Install"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
composer global require php-stubs/wordpress-globals
composer global require php-stubs/wordpress-stubs
composer global require php-stubs/woocommerce-stubs

action "Install Shopify Staff"
brew tap shopify/shopify
require_brew themekit
require_brew shopify-cli

# ###########################################################
bot " Install Gui Applications"
# ###########################################################

read -r -p "Do you want install kitty? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask kitty
else
  ok "skipped"
fi
running "Configuration kitty settings"
ln -s $HOME/.dotfiles/config/kitty  $HOME/.config/kitty
ok
running "reading iterm settings"
defaults read -app iTerm > /dev/null 2>&1;
ok

read -r -p "Do you want install alacritty? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask alacritty

  running "setup Terminal Info"
  git clone https://github.com/alacritty/alacritty.git
  cd alacritty
  sudo tic -xe alacritty,alacritty-direct extra/alacritty.Info
  cd .. && rm -rf alacritty
else
  ok "skipped"
fi

running "Configuration alacritty settings"
ln -s $HOME/.dotfiles/config/alacritty  $HOME/.config/alacritty
ok

read -r -p "Do you want install google-chrome? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask google-chrome
else
  ok "skipped"
fi

read -r -p "Do you want install zoom? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask zoom
else
  ok "skipped"
fi

read -r -p "Do you want install voov-meeting? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask voov-meeting
else
  ok "skipped"
fi

read -r -p "Do you want install keka? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask keka
else
  ok "skipped"
fi

read -r -p "Do you want install whatsapp? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask whatsapp
else
  ok "skipped"
fi


read -r -p "Do you want install vlc? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask vlc
else
  ok "skipped"
fi

read -r -p "Do you want install alfred? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask alfred
else
  ok "skipped"
fi


read -r -p "Do you want install vscode? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  require_cask visual-studio-code
else
  ok "skipped"
fi

read -r -p "Do you want install rectangle? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask rectangle
else
  ok "skipped"
fi

read -r -p "Do you want install wechat? [y|N] " wxresponse
if [[ $wxresponse =~ (y|yes|Y) ]];then
  require_cask wechat
else
  ok "skipped"
fi

brew update && brew upgrade && brew cleanup

bot "All done => check https://gist.github.com/saifulapm/8ef9aade24b171ea204559165f663851"
