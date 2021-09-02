# Enviroment variables
export DOTFILES="$HOME/.dotfiles"
export PROJECTS_DIR="$HOME/Sites"
export PERSONAL_PROJECTS_DIR="$PROJECTS_DIR/Vim"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
# gpg --full-generate-key
export PASSWORD_STORE_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Passwords"

# Add LUA_PATH to the environment ensuring the lua version is set since
# luarocks from homebrew uses lua 5.4 by default so would otherwise add the
# wrong path
if which luarocks >/dev/null; then
  eval "$(luarocks --lua-version=5.1 path)"
fi

#Homebrew's sbin
export PATH="/usr/local/sbin:$PATH"

# Flutter
export PATH="$HOME/sdk/flutter/bin:$PATH"

# Composer
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Java
# sudo ln -sfn /usr/local/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
export PATH="/usr/local/opt/openjdk/bin:$PATH"

# Editor
export EDITOR="nvim"
export GIT_EDITOR="nvim"
export REACT_EDITOR="nvim"

# Bat
export BAT_THEME="TwoDark"

# Fzf
export FZF_COMPLETION_TRIGGER='**'
export FZF_DEFAULT_COMMAND='rg --files --hidden'
export FZF_DEFAULT_OPTS='--height 90% --layout reverse --border --color "border:#b877db" --preview="bat --color=always {}"'
. "$HOME/.cargo/env"
