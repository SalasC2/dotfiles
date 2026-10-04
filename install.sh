#!/usr/bin/env bash
# Puts the files in this repo into $HOME.
#
#   ./install.sh               dry run: only prints what it would do (default)
#   ./install.sh --apply       do it, using symlinks (git pull updates instantly)
#   ./install.sh --apply --copy    copy files instead of symlinking
#   ./install.sh --uninstall --apply   remove our symlinks, restore latest backups
#   ./install.sh --apply nvim  only this piece (names from the repo column below)
#
# Never deletes anything: an existing file is moved to ~/.dotfiles-backup/<time>/
# first. Never uses sudo, never installs packages, never changes your shell.
# Written for bash 3.2 too, so it runs on a fresh Mac before Homebrew's bash.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

APPLY=false
METHOD=link
ACTION=install
ONLY=""

for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=true ;;
        --copy) METHOD=copy ;;
        --uninstall) ACTION=uninstall ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        -*) echo "unknown option: $arg" >&2; exit 1 ;;
        *) ONLY="$ONLY $arg" ;;
    esac
done

if [ "$(id -u)" = 0 ]; then
    echo "Don't run this as root; it installs into your own home folder." >&2
    exit 1
fi

# repo path : path under $HOME
FILES="
bash/bashrc:.bashrc
bash/bashrc.d:.bashrc.d
inputrc:.inputrc
vimrc:.vimrc
tmux.conf:.tmux.conf
gitconfig:.gitconfig
nvim:.config/nvim
"
if [ "$(uname)" = Darwin ]; then
    FILES="$FILES
bash/bash_profile:.bash_profile"
fi

# Print the step; run it only with --apply.
run() {
    if $APPLY; then
        "$@"
    fi
}

install_one() {
    local src="$DOTFILES/$1" dest="$HOME/$2"

    if [ ! -e "$src" ]; then
        echo "MISSING  $1 is not in the repo, skipping" >&2
        return
    fi

    # Already in place?
    if [ "$METHOD" = link ] && [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok       ~/$2"
        return
    fi
    if [ "$METHOD" = copy ] && [ -e "$dest" ] && [ ! -L "$dest" ] && diff -rq "$src" "$dest" >/dev/null 2>&1; then
        echo "ok       ~/$2 (identical copy)"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "backup   ~/$2 -> ${BACKUP/#$HOME/\~}/$2"
        run mkdir -p "$(dirname "$BACKUP/$2")"
        run mv "$dest" "$BACKUP/$2"
    fi

    run mkdir -p "$(dirname "$dest")"
    if [ "$METHOD" = link ]; then
        echo "link     ~/$2 -> $src"
        run ln -s "$src" "$dest"
    else
        echo "copy     $src -> ~/$2"
        run cp -R "$src" "$dest"
    fi
}

uninstall_one() {
    local src="$DOTFILES/$1" dest="$HOME/$2" dir

    if [ ! -L "$dest" ] || [ "$(readlink "$dest")" != "$src" ]; then
        echo "skip     ~/$2 (not a symlink into this repo)"
        return
    fi
    echo "unlink   ~/$2"
    run rm "$dest"

    # Newest backup that has this path wins (timestamps sort correctly).
    for dir in $(ls -1d "$BACKUP_ROOT"/*/ 2>/dev/null | sort -r); do
        if [ -e "$dir$2" ] || [ -L "$dir$2" ]; then
            echo "restore  ${dir/#$HOME/\~}$2 -> ~/$2"
            run mv "$dir$2" "$dest"
            return
        fi
    done
    echo "         (no backup of ~/$2 found; it'll just be gone)"
}

$APPLY || echo "DRY RUN: nothing will change. Re-run with --apply to do it."
echo

echo "$FILES" | while IFS=: read -r src dest; do
    [ -z "$src" ] && continue
    if [ -n "$ONLY" ]; then
        case "$ONLY " in *" $src "*) ;; *) continue ;; esac
    fi
    if [ "$ACTION" = install ]; then
        install_one "$src" "$dest"
    else
        uninstall_one "$src" "$dest"
    fi
done

if [ "$ACTION" = install ] && [ -z "$ONLY" ] && [ ! -f "$HOME/.bashrc.local" ]; then
    echo
    echo "Tip: put machine-only settings in ~/.bashrc.local (see bash/bashrc.local.example)."
fi
