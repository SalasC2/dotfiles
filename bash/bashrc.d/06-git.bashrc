# __git_ps1 is provided by git's bash completion on Ubuntu; on macOS it ships with
# Homebrew's git. Fall back to a no-op so the prompt never prints "command not found".
if ! declare -F __git_ps1 >/dev/null; then
    for f in /usr/lib/git-core/git-sh-prompt "${HOMEBREW_PREFIX-}/etc/bash_completion.d/git-prompt.sh"; do
        [ -r "$f" ] && . "$f" && break
    done
    unset f
fi
declare -F __git_ps1 >/dev/null || __git_ps1() { :; }

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1

