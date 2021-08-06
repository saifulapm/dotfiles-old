# Enviroment variables

# You may need to manually set your language environment
export LANG=en_US.UTF-8
# gpg --full-generate-key
export PASSWORD_STORE_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Passwords"

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
