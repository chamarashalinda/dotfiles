# Installation Guide

## Prerequisites

Before running the bootstrap, make sure the following are available on your machine.

| Requirement | macOS | Linux |
|---|---|---|
| OS version | macOS 13 (Ventura)+ | Ubuntu 22.04+ / Debian 11+ |
| `git` | Xcode CLI tools (`xcode-select --install`) | `sudo apt install git` |
| `curl` | pre-installed | `sudo apt install curl` |
| `sudo` | not required | required |
| Disk space | ≥ 5 GB free | ≥ 5 GB free |
| Internet | required | required |

---

## Step 1 — Clone the repo

```bash
git clone https://github.com/YOUR_USER/dot-files.git ~/.dot-files
cd ~/.dot-files
```

---

## Step 2 — Choose a profile

| Profile | Best for |
|---|---|
| `sre-platform` | SRE, Platform Engineering, DevOps |
| `backend-dev` | Backend / full-stack development |
| `ai-engineering` | ML / AI engineering, LLM work |
| `minimal` | VMs, containers, or a quick base setup |

---

## Step 3 — Run the installer

```bash
bash install.sh --profile <profile-name>
```

### Examples

```bash
# SRE / Platform Engineering (default)
bash install.sh --profile sre-platform

# Backend developer
bash install.sh --profile backend-dev

# AI engineering
bash install.sh --profile ai-engineering

# Minimal — shell + git + dotfiles only
bash install.sh --profile minimal
```

### Not sure? Preview first

```bash
bash install.sh --profile sre-platform --dry-run
```

---

## Step 4 — Post-install

```bash
# Verify all tools installed correctly
make verify

# Reload your shell
exec zsh

# Configure powerlevel10k prompt (first time only)
p10k configure
```

---

## Running a single module

If you only need to (re)install one component:

```bash
make shell       # zsh + oh-my-zsh + powerlevel10k
make packages    # core CLI tools
make languages   # Go, Rust, Python, Node
make cloud       # kubectl, helm, terraform, AWS, GCP
make git         # git config, SSH key, GPG
make themes      # fonts, terminal configs, tmux
make security    # SSH hardening, direnv, sops, age
make dotfiles    # apply dotfiles via chezmoi
```

Or via the install script:

```bash
bash install.sh --module git
bash install.sh --module cloud
```

---

## Setting up chezmoi data (optional)

By default the dotfile templates read values directly from your git config.  
If you want to use the full chezmoi data system (recommended for multiple machines), copy the example config and fill in your values:

```bash
mkdir -p ~/.config/chezmoi
cp docs/chezmoi.toml.example ~/.config/chezmoi/chezmoi.toml
# edit ~/.config/chezmoi/chezmoi.toml with your name, email, GPG key
```

Then re-apply dotfiles:

```bash
make dotfiles
```

---

## Updating everything

After the initial install, keep all tools up to date with:

```bash
make update
```

This updates Homebrew/apt packages, oh-my-zsh, all zsh plugins, Rust, Go tools, pyenv, Node LTS, chezmoi, and dotfiles.
