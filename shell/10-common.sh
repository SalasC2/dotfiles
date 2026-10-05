# Generic aliases, safe on any machine (work laptops too). Must work in bash and zsh.
# Personal stuff goes in 20-personal.sh.

# Editor
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim VISUAL=nvim
    alias vim='nvim'
fi
alias vi='vim'

# Files and navigation
if [ "$(uname)" = Darwin ]; then
    alias ls='ls -aF'
else
    alias ls='ls -aF --color=auto'
fi
alias ll='ls -alF'
alias ..='cd ..'
alias ~='cd ~/'
alias rm='rm -i'
alias mkdir='mkdir -p -v'
alias clr='clear'
command -v pbcopy >/dev/null 2>&1 && alias cptxt='pbcopy <'

# Git
alias add='git add'
alias branch='git branch'
alias co='git checkout'
alias commit='git commit -v'
alias gdiff='git diff'
alias log="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''%C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"
alias merge='git merge'
alias pull='git pull origin'
alias push='git push origin'
alias stash='git stash'
alias status='git status'

# Search and processes
function search_within_files() { grep -r "$1" .; }   # sff <word>: files under . containing it
function find_ports() { lsof -i ":$1"; }               # findport 3000: what's listening
alias sff='search_within_files'
alias findport='find_ports'
alias findpid='ps ax | grep'                           # findpid python

# tmux
alias ta='tmux attach -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias td='tmux detach'
function tsdel() { tmux kill-session -t "$1"; }
function tsrn() { tmux rename-session -t "$1" "$2"; }
alias tx='tmuxinator'

# Languages and tools
alias py='python3'
alias be='bundle exec'
alias sql='sqlite3'

# Vim mode for zsh, same as ~/.inputrc gives bash: Esc = normal mode, the prompt
# starts with [I] (insert) or [N] (normal), cursor is a bar in insert, block in normal.
if [ -n "${ZSH_VERSION-}" ] && [[ -o interactive ]]; then
    bindkey -v
    KEYTIMEOUT=1   # Esc switches instantly (default waits 0.4s)

    # Keep a few emacs-style keys working in insert mode
    bindkey -M viins '^A' beginning-of-line
    bindkey -M viins '^E' end-of-line
    bindkey -M viins '^L' clear-screen
    bindkey -M viins '^W' backward-kill-word
    bindkey -M viins '^?' backward-delete-char   # vi's version stops where insert began
    bindkey -M viins '^H' backward-delete-char

    _vi_mode_update() {
        case $KEYMAP in
            vicmd) _vi_mode='[N] '; printf '\e[2 q' ;;
            *)     _vi_mode='[I] '; printf '\e[6 q' ;;
        esac
        zle reset-prompt
    }
    zle -N _vi_mode_update
    autoload -Uz add-zle-hook-widget
    add-zle-hook-widget keymap-select _vi_mode_update
    add-zle-hook-widget line-init _vi_mode_update

    _vi_mode='[I] '
    setopt prompt_subst
    case $PROMPT in *'${_vi_mode}'*) ;; *) PROMPT='${_vi_mode}'"$PROMPT" ;; esac
fi

# Kubernetes (does nothing until kubectl is installed)
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    if [ -n "${ZSH_VERSION-}" ]; then
        # Needs compinit (Oh My Zsh runs it); a bare zsh would error on every start.
        typeset -f compdef >/dev/null && source <(kubectl completion zsh)
    elif [ -n "${BASH_VERSION-}" ]; then
        source <(kubectl completion bash)
        complete -o default -F __start_kubectl k
    fi
fi
