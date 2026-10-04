# Kubernetes shell setup. Does nothing until kubectl is installed
# (brew bundle --file=~/dotfiles/Brewfile.k8s), so it's safe on every machine.
command -v kubectl >/dev/null 2>&1 || return 0

alias k='kubectl'
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
