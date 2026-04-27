# ========================================
# Environment
# ========================================
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000

# ========================================
# History
# ========================================
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_REDUCE_BLANKS

# ========================================
# Options
# ========================================
setopt AUTO_CD
setopt CORRECT
setopt INTERACTIVE_COMMENTS

# ========================================
# Completion
# ========================================
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ========================================
# Key bindings
# ========================================
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# ========================================
# Aliases
# ========================================
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -a --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias dev='nocorrect dev'
alias ...='cd ../..'
alias k='kubectl'

# ========================================
# Plugins
# ========================================
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ========================================
# Starship prompt (must be last)
# ========================================
eval "$(starship init zsh)"

eval $(keychain --eval --quiet github-ssh-key azure-devops aariatech-server)

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/home/atengku/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# Load venv automatically using this script
eval "$(pyenv virtualenv-init -)"

eval "$(zoxide init zsh)"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/home/atengku/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
