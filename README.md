# dot-files — Developer Workstation Bootstrap Framework

A modular, cross-platform bootstrap framework for macOS and Linux.  
One command fully configures a fresh machine for DevOps, Platform Engineering, SRE, Cloud Engineering, and Software Development workflows.

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USER/dot-files.git ~/.dot-files
cd ~/.dot-files

# 2. Run a profile
bash install.sh --profile sre-platform

# 3. Verify everything installed correctly
make verify
```

---

## Profiles

Pick the profile that matches your role. Each installs only what that role needs.

| Profile | Who it's for | What it installs |
|---|---|---|
| `sre-platform` | SRE / Platform Engineering | Shell, core CLI, Go + Python, full cloud stack (kubectl, helm, terraform, AWS, GCP), security hardening, themes, dotfiles |
| `backend-dev` | Backend Developer | Shell, core CLI, all language runtimes (Go, Rust, Python, Node), minimal cloud (kubectl + Docker), themes, dotfiles |
| `ai-engineering` | AI / ML Engineering | Shell, core CLI, Python + Node, minimal cloud, LLM SDKs (openai, anthropic, langchain), Jupyter, HuggingFace, Ollama |
| `minimal` | VM / container / emergency | Shell, core CLI tools, git config, dotfiles only |

```bash
bash install.sh --profile sre-platform
bash install.sh --profile backend-dev
bash install.sh --profile ai-engineering
bash install.sh --profile minimal
```

---

## Running Individual Modules

Every module is independently runnable. Skip the full profile and install only what you need:

```bash
make shell       # zsh + oh-my-zsh + powerlevel10k + plugins
make packages    # core CLI tools (Homebrew / apt)
make languages   # Go, Rust, Python (pyenv), Node (nvm)
make cloud       # AWS CLI, gcloud, kubectl, helm, terraform (tfenv), k9s
make git         # git config, SSH key, GPG, multi-profile stubs
make themes      # Nerd Fonts, Ghostty / Alacritty / tmux configs
make security    # SSH hardening, direnv, sops, age
make dotfiles    # apply dotfiles via chezmoi
```

Or with the install script:

```bash
bash install.sh --module git
bash install.sh --module languages
```

---

## Dry Run

See exactly what would happen before making any changes:

```bash
bash install.sh --dry-run
bash install.sh --profile minimal --dry-run
```

---

## Verify Installation

After bootstrap, confirm all expected tools are present:

```bash
make verify
```

Prints a pass/fail report grouped by category (Shell, Core CLI, Languages, Cloud, Git). Exits non-zero if anything is missing.

---

## Keeping Tools Updated

```bash
make update
```

Updates Homebrew packages, oh-my-zsh, all zsh plugins, Rust toolchain, Go tools, pyenv, pipx packages, Node LTS, chezmoi, and dotfiles — in one command.

---

## Dotfiles

Dotfiles are managed with [chezmoi](https://chezmoi.io/) and live in the `dotfiles/` directory.

| Source file | Deployed to |
|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `dot_gitconfig.tmpl` | `~/.gitconfig` |
| `dot_aliases` | `~/.aliases` |
| `dot_exports` | `~/.exports` |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` |

To review pending changes before applying:

```bash
chezmoi diff --source="$(pwd)/dotfiles"
```

To re-apply dotfiles at any time:

```bash
make dotfiles
```

---

## What Gets Installed

### Shell
- **zsh** as default shell
- **oh-my-zsh** with plugins: autosuggestions, syntax-highlighting, completions, history-substring-search
- **Powerlevel10k** prompt with instant-prompt enabled

### Core CLI Tools
`bat` `eza` `fzf` `ripgrep` `fd` `jq` `yq` `zoxide` `direnv` `lazygit` `delta` `gh` `tmux`

### Languages
| Runtime | Manager |
|---|---|
| Python | pyenv (default: 3.12) + pipx + poetry, ruff, mypy, black |
| Node.js | nvm (LTS) + pnpm, yarn, tsx, typescript |
| Go | Homebrew / go.dev binary + gopls, dlv, golangci-lint |
| Rust | rustup + clippy, rustfmt, rust-analyzer |

### Cloud (sre-platform / backend-dev)
`kubectl` `kubectx` `helm` `k9s` `stern` `kustomize` `terraform` (via tfenv) `terragrunt` `argocd` `AWS CLI` `gcloud` `OrbStack` (macOS) / `Docker CE` (Linux)

### Security
- Ed25519 SSH key generation
- Hardened SSH config (ControlMaster, AddKeysToAgent)
- GPG + pinentry-mac (macOS)
- `direnv` + `.envrc` workflow
- `sops` + `age` for encrypted secrets
- Global `.gitignore` blocking `.env` and key files

---

## Requirements

| | macOS | Linux |
|---|---|---|
| OS version | 13 (Ventura)+ | Ubuntu 22.04+ / Debian 11+ |
| Pre-installed | `git`, `curl` | `git`, `curl`, `sudo` |
| Disk space | ≥ 5 GB free | ≥ 5 GB free |
| Internet | required | required |

---

## Repository Structure

```
dot-files/
├── install.sh                   # entry point — run this
├── Makefile                     # make targets for every module + profile
├── Taskfile.yml                 # taskfile alternative
│
├── bootstrap/
│   ├── detect.sh                # OS/arch detection, Homebrew PATH init
│   ├── preflight.sh             # internet, disk, sudo, git checks
│   ├── run.sh                   # profile dispatcher
│   └── verify.sh                # post-install health checks
│
├── modules/
│   ├── shell/install.sh         # zsh, oh-my-zsh, p10k, plugins
│   ├── packages/
│   │   ├── install.sh           # Homebrew bundle (macOS) / apt (Linux)
│   │   ├── Brewfile.core        # essential CLI tools
│   │   ├── Brewfile.cloud       # cloud/devops tools
│   │   ├── Brewfile.languages   # language runtimes
│   │   ├── apt_packages.txt     # Linux package list
│   │   └── install_extras_linux.sh  # tools not in apt
│   ├── languages/install.sh     # Go, Rust, Python (pyenv), Node (nvm)
│   ├── cloud/install.sh         # AWS, GCP, kubectl, helm, terraform, k9s
│   ├── git/install.sh           # gitconfig, SSH keygen, GPG, multi-profile
│   ├── themes/install.sh        # Nerd Fonts, terminal configs, tpm
│   ├── security/install.sh      # SSH hardening, GPG, direnv, sops, age
│   └── dotfiles/install.sh      # chezmoi apply
│
├── dotfiles/                    # chezmoi source state
│   ├── dot_zshrc.tmpl
│   ├── dot_gitconfig.tmpl
│   ├── dot_aliases
│   ├── dot_exports
│   └── private_dot_ssh/config.tmpl
│
├── profiles/
│   ├── sre-platform.sh
│   ├── backend-dev.sh
│   ├── ai-engineering.sh
│   └── minimal.sh
│
├── configs/
│   ├── p10k/.p10k.zsh
│   ├── ghostty/config
│   ├── iterm2/profile.json
│   ├── alacritty/alacritty.toml
│   └── tmux/.tmux.conf
│
├── scripts/
│   └── update.sh                # update all installed tools
│
└── docs/
    ├── ARCHITECTURE.md
    ├── INSTALL.md
    ├── TROUBLESHOOTING.md
    └── CONTRIBUTING.md
```

---

## Design Principles

- **Idempotent** — safe to re-run; every step checks before acting
- **Modular** — every module runs independently via `make <module>`
- **Cross-platform** — single codebase for macOS and Ubuntu/Debian
- **Profile-driven** — install only what your role needs
- **No associative arrays** — compatible with macOS bash 3.2
- **Dotfiles via chezmoi** — templated, machine-aware, secret-ready

---

## Docs

- [Installation Guide](docs/INSTALL.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing](docs/CONTRIBUTING.md)

---

## License

MIT — see [LICENSE](LICENSE)
