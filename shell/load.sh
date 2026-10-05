# Shared aliases/functions for bash and zsh. install.sh links this folder's files
# into ~/.config/shell/ and adds one line to ~/.bashrc / ~/.zshrc to source this.
#
#   10-common.sh    generic (ls, git, tmux...), safe on any machine incl. work laptops
#   20-personal.sh  own machines only: install.sh --apply --personal shell
#   90-local.sh     this machine only, not in git: create it by hand if needed
#
# A file is "on" when it's in ~/.config/shell/, so the folder decides per machine.

for _f in "$HOME"/.config/shell/[0-9]*.sh; do
    [ -r "$_f" ] && . "$_f"
done
unset _f
