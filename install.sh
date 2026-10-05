#!/usr/bin/env bash
# Puts the files in this repo into $HOME.
#
#   ./install.sh               dry run: only prints what it would do (default)
#   ./install.sh --apply       do it, using symlinks (git pull updates instantly)
#   ./install.sh --apply --copy    copy files instead of symlinking
#   ./install.sh --uninstall --apply   remove our symlinks, restore latest backups
#   ./install.sh --apply nvim  only this piece (names from the repo column below)
#   ./install.sh --apply shell             shared bash/zsh aliases (generic only)
#   ./install.sh --apply --personal shell  ...plus personal ones (own machines)
#     (shell also adds one line to your own ~/.bashrc / ~/.zshrc to load them)
#
# Never deletes anything: an existing file is moved to ~/.dotfiles-backup/<time>/
# first. Never uses sudo, never installs packages, never changes your shell.
# Written for bash 3.2 too, so it runs on a fresh Mac before Homebrew's bash.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
TILDE="~"   # via a variable: bash 3.2 (macOS) and 5 treat a literal \~ differently
SHOW_BACKUP="${BACKUP/#$HOME/$TILDE}"

APPLY=false
METHOD=link
ACTION=install
ONLY=""
PERSONAL=false

for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=true ;;
        --copy) METHOD=copy ;;
        --uninstall) ACTION=uninstall ;;
        --personal) PERSONAL=true ;;
        -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
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
shell/load.sh:.config/shell/load.sh
shell/10-common.sh:.config/shell/10-common.sh
"
# Personal aliases only where asked for. Uninstall always considers them.
if $PERSONAL || [ "$ACTION" = uninstall ]; then
    FILES="$FILES
shell/20-personal.sh:.config/shell/20-personal.sh"
fi
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
        echo "backup   ~/$2 -> $SHOW_BACKUP/$2"
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
            echo "restore  ${dir/#$HOME/$TILDE}$2 -> ~/$2"
            run mv "$dir$2" "$dest"
            return
        fi
    done
    echo "         (no backup of ~/$2 found; it'll just be gone)"
}

# The one line that loads the shared aliases from ~/.bashrc / ~/.zshrc.
RC_LINE='[ -f ~/.config/shell/load.sh ] && . ~/.config/shell/load.sh  # dotfiles shell aliases'

# Add RC_LINE to the user's own rc files (not ones linked from this repo:
# bash/bashrc.d/09-shell.bashrc already loads the aliases). Backs up first.
hook_rc() {
    local rc dest
    for rc in .bashrc .zshrc; do
        dest="$HOME/$rc"
        [ -f "$dest" ] || continue
        case "$(readlink "$dest" 2>/dev/null)" in "$DOTFILES"/*) continue ;; esac
        # This run is linking the repo's bashrc over it, so leave it alone.
        if [ "$rc" = .bashrc ]; then
            case " ${ONLY:- bash} " in *" bash "*|*" bash/bashrc "*) continue ;; esac
        fi
        if grep -qF "$RC_LINE" "$dest"; then
            echo "ok       ~/$rc loads ~/.config/shell"
        else
            echo "backup   ~/$rc -> $SHOW_BACKUP/$rc (copy)"
            echo "append   ~/$rc: $RC_LINE"
            run mkdir -p "$BACKUP"
            run cp -p "$dest" "$BACKUP/$rc"
            if $APPLY; then
                # Start on a fresh line, so uninstall can give back the exact file.
                [ -z "$(tail -c1 "$dest")" ] || echo >> "$dest"
                echo "$RC_LINE" >> "$dest"
            fi
        fi
    done
}

unhook_rc() {
    local rc dest
    for rc in .bashrc .zshrc; do
        dest="$HOME/$rc"
        [ -f "$dest" ] && grep -qF "$RC_LINE" "$dest" || continue
        case "$(readlink "$dest" 2>/dev/null)" in "$DOTFILES"/*) continue ;; esac
        echo "backup   ~/$rc -> $SHOW_BACKUP/$rc (copy)"
        echo "remove   ~/$rc: the dotfiles shell aliases line"
        run mkdir -p "$BACKUP"
        run cp -p "$dest" "$BACKUP/$rc"
        if $APPLY; then
            grep -vF "$RC_LINE" "$BACKUP/$rc" > "$dest" || true   # no lines left is fine
        fi
    done
}

$APPLY || echo "DRY RUN: nothing will change. Re-run with --apply to do it."
echo

echo "$FILES" | while IFS=: read -r src dest; do
    [ -z "$src" ] && continue
    if [ -n "$ONLY" ]; then
        # "shell" picks up shell/load.sh etc.
        case "$ONLY " in *" $src "*|*" ${src%%/*} "*) ;; *) continue ;; esac
    fi
    if [ "$ACTION" = install ]; then
        install_one "$src" "$dest"
    else
        uninstall_one "$src" "$dest"
    fi
done

case " ${ONLY:- shell} " in
    *" shell "*)
        if [ "$ACTION" = install ]; then hook_rc; else unhook_rc; fi ;;
esac

if [ "$ACTION" = install ] && [ -z "$ONLY" ] && [ ! -f "$HOME/.bashrc.local" ]; then
    echo
    echo "Tip: put machine-only settings in ~/.bashrc.local (see bash/bashrc.local.example)."
fi
