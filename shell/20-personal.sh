# Personal aliases/functions: own machines only (install.sh --apply --personal shell).
# Must work in bash and zsh. Mac-only commands are guarded so Linux doesn't complain.

alias nvim-kickstart='NVIM_APPNAME="nvim-kickstart" nvim'
function rls() { rails new "$1" -d postgresql; }

# Shell config shortcuts
alias zshrc='vim ~/.zshrc'
alias zshalias='vim ~/dotfiles/shell'
alias zshbuiltins='man zshbuiltins'
alias reloadshell='exec "$SHELL" -l'

# Fun / Mac
command -v say >/dev/null 2>&1 && alias today='echo "hi $USER, today is $(date +%F)" | say'
command -v mpg123 >/dev/null 2>&1 && alias mu='mpg123 ~/yes.mp3 || mpg123 ~/fail.mp3'
command -v subl >/dev/null 2>&1 && alias sub='subl'
[ "$(uname)" = Darwin ] && alias resetBluetoothAudio='sudo killall coreaudiod'

# nvm from Homebrew, loaded on first use so shells start fast.
# Skipped where nvm is already loaded (the repo's bash setup loads ~/.nvm eagerly).
if ! command -v nvm >/dev/null 2>&1 && [ -s /opt/homebrew/opt/nvm/nvm.sh ]; then
    export NVM_DIR="$HOME/.nvm"
    _nvm_load() { unset -f nvm node npm npx _nvm_load; . /opt/homebrew/opt/nvm/nvm.sh; }
    function nvm() { _nvm_load; nvm "$@"; }
    function node() { _nvm_load; node "$@"; }
    function npm() { _nvm_load; npm "$@"; }
    function npx() { _nvm_load; npx "$@"; }
fi
