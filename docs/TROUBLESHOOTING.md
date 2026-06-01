# Troubleshooting

## Installation

---

### `brew: command not found` during a module run

Homebrew is installed but not on the current PATH.  
This is handled automatically — `bootstrap/detect.sh` initialises Homebrew's PATH when sourced. If you see this running a module manually, source detect.sh first or reload your shell:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"       # Intel Mac
```

---

### `chsh` fails or asks for a password on macOS

```bash
chsh -s $(which zsh)
# enter your macOS login password when prompted
```

If it still fails, add zsh to `/etc/shells` manually:

```bash
echo "$(which zsh)" | sudo tee -a /etc/shells
chsh -s $(which zsh)
```

---

### Preflight fails: internet connectivity

Check your network. If behind a corporate proxy:

```bash
export https_proxy=http://proxy.example.com:8080
export http_proxy=http://proxy.example.com:8080
bash install.sh --profile minimal
```

---

### Preflight fails: disk space

The bootstrap needs ≥ 5 GB free. Free up space then re-run:

```bash
df -h ~           # check available space
make verify       # re-run checks after freeing space
```

---

## Shell

---

### Powerlevel10k prompt looks broken / shows boxes

Your terminal is not using a Nerd Font. Fix:

1. Install the font (already done by `make themes`):
   - **Ghostty / Alacritty**: config already sets `JetBrainsMono Nerd Font`
   - **iTerm2**: Preferences → Profiles → Text → change font to `MesloLGS NF` or `JetBrainsMono Nerd Font`
   - **macOS Terminal**: not recommended — use Ghostty, iTerm2, or Alacritty

2. Re-run the prompt wizard:
   ```bash
   p10k configure
   ```

---

### oh-my-zsh plugins not loading

Check that the plugin directories exist:

```bash
ls ~/.oh-my-zsh/custom/plugins/
```

If missing, re-run:

```bash
make shell
```

---

## Languages

---

### pyenv: Python build fails on Linux

Missing build dependencies. Install them first:

```bash
sudo apt-get install -y \
  libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev \
  libffi-dev liblzma-dev libncurses5-dev
```

Then retry:

```bash
pyenv install 3.12
```

---

### `nvm: command not found` after install

nvm is loaded by your shell config, not available in subshells. Either:

```bash
# Load it manually for this session
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
```

Or reload your shell:

```bash
exec zsh
```

---

### `node: command not found` after nvm install

You need to set a default Node version:

```bash
nvm alias default node
nvm use default
```

---

### Go tools (`gopls`, `dlv`) not found

Ensure `GOPATH/bin` is on your PATH. It's added in `~/.exports`, so reload:

```bash
exec zsh
which gopls    # should resolve now
```

---

## Cloud Tools

---

### `kubectl` not connecting to cluster

```bash
kubectl config get-contexts           # list available contexts
kubectl config use-context <name>     # switch context
kubectl cluster-info                  # verify connection
```

---

### `tfenv` — no terraform version installed

```bash
tfenv install latest
tfenv use latest
terraform --version
```

---

### `gcloud` components not found after install

On Linux, the `gke-gcloud-auth-plugin` is installed separately:

```bash
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
```

On macOS:

```bash
gcloud components install gke-gcloud-auth-plugin
```

---

### `argocd: command not found`

argocd CLI is installed to `/usr/local/bin`. Check it's on your PATH:

```bash
ls /usr/local/bin/argocd
which argocd
```

If missing, re-run the cloud module:

```bash
make cloud
```

---

## Dotfiles

---

### `chezmoi: no such file or directory`

The `--source` flag is required. All chezmoi commands in this repo pass it automatically. If running chezmoi manually:

```bash
chezmoi apply --source="$HOME/.dot-files/dotfiles"
chezmoi diff  --source="$HOME/.dot-files/dotfiles"
```

---

### chezmoi template error: `map has no entry for key`

The template references a chezmoi data variable (e.g., `.gitName`) that isn't configured.  
Set up `~/.config/chezmoi/chezmoi.toml` from the example:

```bash
mkdir -p ~/.config/chezmoi
cp docs/chezmoi.toml.example ~/.config/chezmoi/chezmoi.toml
# fill in your name, email, etc.
make dotfiles
```

---

### `.gitconfig` getting overwritten on every `make dotfiles`

This is expected — chezmoi manages `~/.gitconfig` from `dot_gitconfig.tmpl`.  
All your git settings should be in the template or set via env vars before running the git module (`GIT_USER_NAME`, `GIT_USER_EMAIL`).

---

## Git & SSH

---

### SSH key not being picked up

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com      # test GitHub connection
```

---

### GPG passphrase prompt not appearing on macOS

pinentry-mac may not be configured:

```bash
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

---

## General

---

### Re-running a module after a failure

All modules are idempotent — safe to re-run. Just call the make target again:

```bash
make languages    # re-run languages module
make verify       # check what's still missing
```

---

### Checking what a profile would install without running it

```bash
bash install.sh --profile sre-platform --dry-run
```
