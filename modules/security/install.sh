#!/usr/bin/env bash
# modules/security/install.sh — Security hardening and tooling (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
info()  { echo -e "${YELLOW}ℹ${RESET} $*"; }

echo -e "\n${BOLD}[security] Applying security hardening and tooling...${RESET}\n"

# ─── SSH hardening ────────────────────────────────────────────────────────────
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Fix permissions on any existing key files
find "$SSH_DIR" -maxdepth 1 \( -name "id_*" -not -name "*.pub" \) -exec chmod 600 {} \;
find "$SSH_DIR" -maxdepth 1 -name "*.pub" -exec chmod 644 {} \;
find "$SSH_DIR" -maxdepth 1 -name "known_hosts" -exec chmod 600 {} \;
done_ "SSH directory permissions hardened (700/600)"

# SSH config with hardened defaults
SSH_CONFIG="$SSH_DIR/config"
if [[ ! -f "$SSH_CONFIG" ]]; then
  log "Writing hardened SSH client config..."
  if command -v chezmoi &>/dev/null; then
    chezmoi apply
  else
    install -m 600 "$REPO_ROOT/dotfiles/private_dot_ssh/config.tmpl" "$SSH_CONFIG"
  fi
  done_ "SSH config applied"
else
  # Ensure ControlMaster and HashKnownHosts are present
  if ! grep -q "ControlMaster" "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" <<'EOF'

Host *
    HashKnownHosts yes
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    mkdir -p "$SSH_DIR/sockets"
    chmod 700 "$SSH_DIR/sockets"
    done_ "SSH config hardened"
  else
    done_ "SSH config already hardened"
  fi
fi

# ─── GPG + pinentry ───────────────────────────────────────────────────────────
if ! command -v gpg &>/dev/null; then
  log "Installing gnupg..."
  if is_mac; then
    brew install gnupg
  else
    sudo apt-get install -y gnupg
  fi
  done_ "gnupg installed"
else
  done_ "gnupg already installed"
fi

GPG_AGENT_CONF="$HOME/.gnupg/gpg-agent.conf"
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

if is_mac; then
  if ! command -v pinentry-mac &>/dev/null; then
    log "Installing pinentry-mac..."
    brew install pinentry-mac
    done_ "pinentry-mac installed"
  else
    done_ "pinentry-mac already installed"
  fi

  PINENTRY_PATH="$(command -v pinentry-mac)"
  if [[ ! -f "$GPG_AGENT_CONF" ]] || ! grep -q "pinentry-program" "$GPG_AGENT_CONF"; then
    echo "pinentry-program $PINENTRY_PATH" >> "$GPG_AGENT_CONF"
    done_ "gpg-agent.conf configured with pinentry-mac"
  else
    done_ "gpg-agent.conf already configured"
  fi
fi

# Ensure GPG_TTY is set (also handled in dot_exports, this is a safety fallback)
if ! grep -q "GPG_TTY" "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null; then
  info "GPG_TTY is set via ~/.exports — ensure that file is sourced in your shell"
fi

# ─── direnv ───────────────────────────────────────────────────────────────────
if ! command -v direnv &>/dev/null; then
  log "Installing direnv..."
  if is_mac; then
    brew install direnv
  else
    sudo apt-get install -y direnv
  fi
  done_ "direnv installed"
else
  done_ "direnv $(direnv --version) already installed"
fi


# ─── sops + age ───────────────────────────────────────────────────────────────
if ! command -v sops &>/dev/null; then
  log "Installing sops..."
  if is_mac; then
    brew install sops
  else
    _version="$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest \
      | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
    _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
    curl -fsSL "https://github.com/getsops/sops/releases/download/v${_version}/sops-v${_version}.linux.${_arch_tag}" \
      | sudo tee /usr/local/bin/sops >/dev/null
    sudo chmod +x /usr/local/bin/sops
  fi
  done_ "sops installed"
else
  done_ "sops $(sops --version | awk '{print $2}') already installed"
fi

if ! command -v age &>/dev/null; then
  log "Installing age..."
  if is_mac; then
    brew install age
  else
    _version="$(curl -fsSL https://api.github.com/repos/FiloSottile/age/releases/latest \
      | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
    _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
    TMP_DIR="$(mktemp -d)"
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${_version}/age-v${_version}-linux-${_arch_tag}.tar.gz" \
      | tar -xz -C "$TMP_DIR"
    sudo mv "$TMP_DIR/age/age" "$TMP_DIR/age/age-keygen" /usr/local/bin/
    rm -rf "$TMP_DIR"
  fi
  done_ "age installed"
else
  done_ "age $(age --version) already installed"
fi

# ─── Global .gitignore ────────────────────────────────────────────────────────
GLOBAL_GITIGNORE="$HOME/.gitignore_global"
if [[ ! -f "$GLOBAL_GITIGNORE" ]]; then
  log "Creating global .gitignore..."
  cat > "$GLOBAL_GITIGNORE" <<'EOF'
# Secrets & environment
.env
.env.*
!.env.example
.envrc
*.pem
*.key
*.p12
*.pfx
secrets/
.secrets/

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Editor
.vscode/settings.json
.idea/
*.swp
*.swo
*~
EOF
  git config --global core.excludesfile "$GLOBAL_GITIGNORE"
  done_ "Global .gitignore created and registered"
else
  done_ "Global .gitignore already present"
fi

# Ensure git knows about it
git config --global core.excludesfile "$GLOBAL_GITIGNORE" 2>/dev/null || true

# ─── .envrc example ───────────────────────────────────────────────────────────
ENVRC_EXAMPLE="$HOME/.envrc.example"
if [[ ! -f "$ENVRC_EXAMPLE" ]]; then
  cat > "$ENVRC_EXAMPLE" <<'EOF'
# .envrc — direnv configuration (copy to project root as .envrc)
# Run `direnv allow` after creating this file.

# Load .env file if present
dotenv_if_exists .env

# Python virtualenv (pyenv-virtualenv)
# layout pyenv 3.12.0

# Set project-specific env vars
# export DATABASE_URL=postgres://localhost/mydb
# export REDIS_URL=redis://localhost:6379
EOF
  done_ "~/.envrc.example created"
fi

echo -e "\n${GREEN}${BOLD}[security] Done.${RESET}\n"
