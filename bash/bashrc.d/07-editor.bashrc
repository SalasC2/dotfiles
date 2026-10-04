# Runs after 05-completion so Homebrew is on PATH (matters on macOS).
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim VISUAL=nvim
    alias vim='nvim'
fi
