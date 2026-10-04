# dotfiles

Bash + Neovim (LazyVim) + tmux setup shared across Ubuntu, macOS and WSL.

## New machine

```bash
# 1. Homebrew (https://brew.sh), then the tools
brew bundle --file=~/dotfiles/Brewfile          # add Brewfile.k8s for kubectl/flux/k9s

# 2. Config. Dry run first, read the output, then apply
git clone https://github.com/SalasC2/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
~/dotfiles/install.sh --apply

# 3. Neovim plugins at the versions pinned in lazy-lock.json
nvim --headless "+Lazy! restore" +qa
```

### macOS only: make Homebrew's bash your shell (macOS ships bash 3.2)

```bash
echo "$(brew --prefix)/bin/bash" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/bash"
```

If a managed work Mac blocks `chsh`, set the terminal app to run
`/opt/homebrew/bin/bash -l` instead (iTerm2: Profiles > General > Command).

Also set the terminal font to "JetBrainsMono Nerd Font" so Neovim icons render.

## Optional: Kubernetes tools

Separate step, only on machines that need it:

```bash
brew bundle --file=~/dotfiles/Brewfile.k8s   # kubectl, flux, kubectx, k9s
```

`bash/bashrc.d/08-k8s.bashrc` (the `k` alias + completion) switches itself on once
kubectl exists. Cluster credentials (`~/.kube/config`) never go in this repo: each
machine gets its own from the cluster or from work.

## Per-machine settings (never committed)

- `~/.bashrc.local`: PATH tweaks, env vars (see `bash/bashrc.local.example`)
- `~/.gitconfig.local`: **required**, sets this machine's commit email:
  ```
  [user]
  	email = salasch2@gmail.com   # personal machines; work email on the work laptop
  ```
  Git refuses to commit until this exists, so work commits can't go out under the
  personal email by accident.

### Coming from an existing setup (e.g. a work laptop)

Run the dry run first. Anything it says it will back up may contain company settings
(proxy, certificates, internal git URLs). Move those into `~/.bashrc.local` /
`~/.gitconfig.local`. If you're switching from zsh, check `~/.zshrc` and `~/.zprofile`
too: bash won't read them.

## Undo

`~/dotfiles/install.sh --uninstall --apply` removes the symlinks and restores the
newest backups from `~/.dotfiles-backup/`.
