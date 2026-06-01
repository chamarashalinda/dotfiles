#!/usr/bin/env bash
# modules/languages/install.sh — Language runtime installation (idempotent)
#
# Env vars:
#   PYTHON_VERSION  Python version to install via pyenv (default: 3.12)
#   SKIP_GO         set to 1 to skip Go
#   SKIP_RUST       set to 1 to skip Rust
#   SKIP_PYTHON     set to 1 to skip Python
#   SKIP_NODE       set to 1 to skip Node

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
skip()  { echo -e "${YELLOW}–${RESET} Skipping $*"; }

PYTHON_VERSION="${PYTHON_VERSION:-3.12}"

echo -e "\n${BOLD}[languages] Installing language runtimes...${RESET}\n"

# ─── Go ───────────────────────────────────────────────────────────────────────
if [[ "${SKIP_GO:-0}" == "1" ]]; then
  skip "Go"
else
  if ! command -v go &>/dev/null; then
    log "Installing Go..."
    if is_mac; then
      brew install go
    else
      _go_version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1)"
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
      _url="https://go.dev/dl/${_go_version}.linux-${_arch_tag}.tar.gz"
      log "Downloading ${_go_version} for linux/${_arch_tag}..."
      curl -fsSL "$_url" | sudo tar -xz -C /usr/local
      sudo ln -sf /usr/local/go/bin/go   /usr/local/bin/go
      sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    fi
    done_ "Go $(go version | awk '{print $3}') installed"
  else
    done_ "Go $(go version | awk '{print $3}') already installed"
  fi

  # Go dev tools
  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$GOPATH/bin:$PATH"
  for tool in \
      "golang.org/x/tools/gopls@latest" \
      "github.com/go-delve/delve/cmd/dlv@latest" \
      "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; do
    name="$(basename "${tool%@*}")"
    if ! command -v "$name" &>/dev/null; then
      log "Installing $name..."
      go install "$tool"
      done_ "$name installed"
    else
      done_ "$name already installed"
    fi
  done
fi

# ─── Rust ─────────────────────────────────────────────────────────────────────
if [[ "${SKIP_RUST:-0}" == "1" ]]; then
  skip "Rust"
else
  if ! command -v rustc &>/dev/null; then
    log "Installing Rust via rustup..."
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
    done_ "Rust installed"
  else
    done_ "Rust $(rustc --version | awk '{print $2}') already installed"
  fi

  # Ensure cargo env is sourced for this session
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

  for component in clippy rustfmt rust-analyzer; do
    if ! rustup component list --installed 2>/dev/null | grep -q "^${component}"; then
      log "Adding rustup component: $component..."
      rustup component add "$component"
      done_ "$component added"
    else
      done_ "rustup component $component already installed"
    fi
  done
fi

# ─── Python ───────────────────────────────────────────────────────────────────
if [[ "${SKIP_PYTHON:-0}" == "1" ]]; then
  skip "Python"
else
  if ! command -v pyenv &>/dev/null; then
    log "Installing pyenv..."
    if is_mac; then
      brew install pyenv pyenv-virtualenv
    else
      curl -fsSL https://pyenv.run | bash
      export PYENV_ROOT="$HOME/.pyenv"
      export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    done_ "pyenv installed"
  else
    done_ "pyenv $(pyenv --version | awk '{print $2}') already installed"
  fi

  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)" 2>/dev/null || true

  if ! pyenv versions --bare 2>/dev/null | grep -q "^${PYTHON_VERSION}"; then
    log "Installing Python ${PYTHON_VERSION} via pyenv..."
    pyenv install "$PYTHON_VERSION"
    done_ "Python ${PYTHON_VERSION} installed"
  else
    done_ "Python ${PYTHON_VERSION} already installed via pyenv"
  fi

  pyenv global "$PYTHON_VERSION"
  done_ "Python ${PYTHON_VERSION} set as global default"

  # pipx + dev tools
  if ! command -v pipx &>/dev/null; then
    log "Installing pipx..."
    pip install --quiet --upgrade pipx
    python3 -m pipx ensurepath
    done_ "pipx installed"
  else
    done_ "pipx already installed"
  fi

  for pkg in poetry ruff mypy black; do
    if ! pipx list 2>/dev/null | grep -q "$pkg"; then
      log "Installing $pkg via pipx..."
      pipx install "$pkg"
      done_ "$pkg installed"
    else
      done_ "$pkg already installed"
    fi
  done
fi

# ─── Node (via nvm) ───────────────────────────────────────────────────────────
if [[ "${SKIP_NODE:-0}" == "1" ]]; then
  skip "Node"
else
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    log "Installing nvm..."
    if is_mac; then
      brew install nvm
      mkdir -p "$NVM_DIR"
    else
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
    fi
    done_ "nvm installed"
  else
    done_ "nvm already installed"
  fi

  # Load nvm for this session
  # shellcheck source=/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

  if ! nvm list 2>/dev/null | grep -q "lts"; then
    log "Installing Node LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default node
    done_ "Node $(node --version) installed (LTS)"
  else
    done_ "Node LTS already installed via nvm"
  fi

  for pkg in pnpm yarn tsx typescript; do
    if ! npm list -g --depth=0 2>/dev/null | grep -q "$pkg"; then
      log "Installing $pkg globally..."
      npm install -g "$pkg" --silent
      done_ "$pkg installed"
    else
      done_ "$pkg already installed globally"
    fi
  done
fi

echo -e "\n${GREEN}${BOLD}[languages] Done.${RESET}\n"
