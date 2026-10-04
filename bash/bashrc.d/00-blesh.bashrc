# ble.sh: fish/zsh-style inline autosuggestions + syntax highlighting for bash.
# Must be sourced before other prompt/completion setup for it to attach cleanly.
[ -f ~/.local/share/blesh/ble.sh ] && source ~/.local/share/blesh/ble.sh --noattach

# Case-insensitive tab completion (readline-level, also honored by ble.sh)
bind 'set completion-ignore-case on' 2>/dev/null
