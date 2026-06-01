# Architecture

## Overview

The framework is a layered shell-script system orchestrated by Make.  
Each layer has a single responsibility and can run independently.

```
┌──────────────────────────────────────────────────────┐
│           Entry Point — install.sh                   │
│         (flag parsing, repo check, dispatch)         │
├──────────────────────────────────────────────────────┤
│              Orchestration — Makefile                │
├───────────────────────┬──────────────────────────────┤
│  bootstrap/detect.sh  │  bootstrap/preflight.sh      │
│  (OS, arch, PATH)     │  (internet, disk, sudo, git) │
├───────────────────────┴──────────────────────────────┤
│              bootstrap/run.sh                        │
│           (profile dispatcher)                       │
├──────────┬───────────┬───────────┬───────────────────┤
│  shell   │ packages  │ languages │      cloud        │
│  git     │ themes    │ security  │     dotfiles      │
├──────────┴───────────┴───────────┴───────────────────┤
│       OS Abstraction — brew (macOS) · apt (Linux)    │
├──────────┬───────────┬──────────────┬────────────────┤
│sre-      │backend-   │ai-           │minimal         │
│platform  │dev        │engineering   │                │
└──────────┴───────────┴──────────────┴────────────────┘
```

---

## Key Design Decisions

### Idempotency
Every install step checks before acting — `command -v`, `[[ -d ]]`, `[[ -f ]]`.  
Running `make bootstrap` twice is safe and fast; only missing pieces install.

### OS Abstraction in One Place
`bootstrap/detect.sh` is sourced by every module as its first action.  
It exports:
- `OS_TYPE` — `macos` | `linux`
- `ARCH` — `amd64` | `arm64`
- `PKG_MANAGER` — `brew` | `apt` | `dnf`
- `IS_MAC` / `IS_LINUX` — booleans
- Helper functions: `is_mac()`, `is_linux()`, `is_arm()`, `is_ubuntu()`

It also initialises Homebrew's PATH on macOS (both Intel `/usr/local` and Apple Silicon `/opt/homebrew`), so every module that sources it gets `brew` available automatically.

No module calls `uname` directly — they use the helpers.

### Package Management Strategy

**macOS — Homebrew + Brewfiles**

Packages are declared in split Brewfiles:

| File | Purpose |
|---|---|
| `Brewfile.core` | Essential CLI tools for every profile |
| `Brewfile.cloud` | Cloud & Kubernetes tools (sre-platform) |
| `Brewfile.languages` | Language runtime managers |

Profiles compose these by setting `BREWFILE_EXTRA` before running the packages module.

**Linux — apt + direct binaries**

Base packages come from `apt_packages.txt`.  
Modern tools not in apt (`eza`, `lazygit`, `yq`, `delta`, `gh`, `zoxide`) are installed as binaries from their official GitHub releases by `install_extras_linux.sh`, with architecture detection for amd64/arm64.

### Language Runtimes — Version Managers Only

System package managers are never used for language runtimes.

| Language | Manager | Reason |
|---|---|---|
| Python | pyenv | Exact version control, virtualenv isolation |
| Node.js | nvm | LTS management, per-project `.nvmrc` support |
| Go | Homebrew / go.dev | Single active version, simple |
| Rust | rustup | Official toolchain manager, component system |

### Bash 3.2 Compatibility

macOS ships with bash 3.2 (due to GPL licensing). The codebase avoids features that require bash 4+:

- No `declare -A` associative arrays — use helper functions instead
- No `mapfile` / `readarray`
- All scripts use `#!/usr/bin/env bash` with `set -euo pipefail`

### Dotfiles — chezmoi

chezmoi manages personal config files with Go templating.

**Why chezmoi over GNU stow:**
- Templates allow machine-specific config (work vs personal, macOS vs Linux)
- Native secret integration (1Password, age, sops)
- Handles files that can't be symlinked (macOS SIP-protected paths)
- `chezmoi diff` gives an auditable preview before applying

**Source naming convention:**

| Source name | Deployed path | Notes |
|---|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` | templated |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | reads from git config |
| `dot_aliases` | `~/.aliases` | plain file |
| `dot_exports` | `~/.exports` | plain file |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` | templated, 600 perms |

The `--source` flag is always passed explicitly so chezmoi uses the repo's `dotfiles/` directory rather than `~/.local/share/chezmoi`.

### Profiles — Ordered Declarations

Profiles contain no logic. They are ordered sequences of `bash module/install.sh` calls with environment variable overrides.

```bash
# profiles/sre-platform.sh (simplified)
bash "$REPO_ROOT/modules/shell/install.sh"
BREWFILE_EXTRA="$REPO_ROOT/modules/packages/Brewfile.cloud" \
  bash "$REPO_ROOT/modules/packages/install.sh"
SKIP_RUST=1 SKIP_NODE=1 \
  bash "$REPO_ROOT/modules/languages/install.sh"
bash "$REPO_ROOT/modules/cloud/install.sh"
```

All logic lives in modules. Profiles are readable declarations of intent.

### Module Environment Variables

Modules accept env vars for selective behaviour:

| Module | Variable | Effect |
|---|---|---|
| `languages` | `SKIP_GO=1` | Skip Go installation |
| `languages` | `SKIP_RUST=1` | Skip Rust installation |
| `languages` | `SKIP_PYTHON=1` | Skip Python installation |
| `languages` | `SKIP_NODE=1` | Skip Node installation |
| `languages` | `PYTHON_VERSION=3.12` | Override Python version |
| `packages` | `BREWFILE_EXTRA=<path>` | Bundle an additional Brewfile |
| `cloud` | `CLOUD_MINIMAL=1` | Install kubectl + Docker only |
| `cloud` | `SKIP_AWS=1` | Skip AWS tooling |
| `cloud` | `SKIP_GCP=1` | Skip GCP tooling |
| `cloud` | `SKIP_TERRAFORM=1` | Skip Terraform tooling |
| `git` | `GIT_USER_NAME=` | Pre-set git user name |
| `git` | `GIT_USER_EMAIL=` | Pre-set git email |
| `git` | `GPG_KEY_ID=` | Configure commit signing |

### Security Defaults

- SSH keys: Ed25519 only (not RSA or ECDSA)
- SSH config: `ControlMaster auto`, `AddKeysToAgent yes`, `HashKnownHosts yes`
- SSH directory: 700, key files: 600 (enforced by security module)
- GPG: pinentry-mac on macOS for GUI passphrase prompts
- Secrets: `.env` files managed via direnv, never committed
- Global gitignore: blocks `.env`, `*.pem`, `*.key`, `secrets/`
- `sops` + `age`: available for encrypting secrets in the repo

---

## Module Interface Contract

Every `modules/*/install.sh` must follow this contract:

1. **Source detect.sh first** — `source "$REPO_ROOT/bootstrap/detect.sh"`
2. **Be idempotent** — every action is guarded by a check
3. **Coloured output** — `log()` for actions, `done_()` for completions, `skip()` for skipped steps
4. **Accept env overrides** — version and skip flags documented in the header comment
5. **Exit cleanly** — `set -euo pipefail` at the top; non-zero on real failure

---

## Extending the Framework

### Add a new module

```bash
mkdir -p modules/mymodule
cat > modules/mymodule/install.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/bootstrap/detect.sh"
# ... your install logic
EOF
```

Then add a `make` target:
```makefile
## mymodule: Description of what it installs
mymodule:
	@bash modules/mymodule/install.sh
```

And include it in the relevant profiles.

### Add a new profile

```bash
cp profiles/minimal.sh profiles/myprofile.sh
# edit to source the modules you need in order
# test:
make bootstrap PROFILE=myprofile
```

### Add a new dotfile

Add the file to `dotfiles/` using chezmoi naming:
- `dot_filename` → `~/.filename`
- `dot_filename.tmpl` → `~/.filename` (rendered as Go template)
- `private_dot_filename` → `~/.filename` with 600 permissions

---

## Future Directions

- `modules/neovim/` — LazyVim-based Neovim config
- `modules/vscode/` — extensions + settings bootstrap
- `modules/k8s-local/` — kind / k3d local cluster setup
- `modules/tailscale/` — VPN setup
- `profiles/homelab.sh` — self-hosted / homelab profile
- Per-project dev environments via Devbox / Nix flakes
