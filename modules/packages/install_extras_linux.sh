#!/usr/bin/env bash
# install_extras_linux.sh — Install modern CLI tools not available in apt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }

_gh_latest() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name": "v\?\([^"]*\)".*/\1/'
}

# eza — via official apt repo
if ! command -v eza &>/dev/null; then
  log "Installing eza..."
  sudo apt-get install -y gpg
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update -qq
  sudo apt-get install -y eza
  done_ "eza installed"
else
  done_ "eza already installed"
fi

# zoxide
if ! command -v zoxide &>/dev/null; then
  log "Installing zoxide..."
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  done_ "zoxide installed"
else
  done_ "zoxide already installed"
fi

# lazygit
if ! command -v lazygit &>/dev/null; then
  VERSION="$(_gh_latest jesseduffield/lazygit)"
  ARCH_TAG="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "x86_64")"
  URL="https://github.com/jesseduffield/lazygit/releases/download/v${VERSION}/lazygit_${VERSION}_Linux_${ARCH_TAG}.tar.gz"
  log "Installing lazygit ${VERSION}..."
  TMP_DIR="$(mktemp -d)"
  curl -fsSL "$URL" | tar -xz -C "$TMP_DIR"
  sudo mv "$TMP_DIR/lazygit" /usr/local/bin/lazygit
  rm -rf "$TMP_DIR"
  done_ "lazygit installed"
else
  done_ "lazygit already installed"
fi

# yq
if ! command -v yq &>/dev/null; then
  VERSION="$(_gh_latest mikefarah/yq)"
  ARCH_TAG="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
  URL="https://github.com/mikefarah/yq/releases/download/v${VERSION}/yq_linux_${ARCH_TAG}"
  log "Installing yq ${VERSION}..."
  TMP="$(mktemp)"
  curl -fsSL "$URL" -o "$TMP"
  chmod +x "$TMP"
  sudo mv "$TMP" /usr/local/bin/yq
  done_ "yq installed"
else
  done_ "yq already installed"
fi

# delta (git diff enhancer)
if ! command -v delta &>/dev/null; then
  VERSION="$(_gh_latest dandavison/delta)"
  ARCH_TAG="$([ "$ARCH" = "arm64" ] && echo "aarch64" || echo "x86_64")"
  URL="https://github.com/dandavison/delta/releases/download/${VERSION}/delta-${VERSION}-${ARCH_TAG}-unknown-linux-musl.tar.gz"
  log "Installing delta ${VERSION}..."
  TMP_DIR="$(mktemp -d)"
  curl -fsSL "$URL" | tar -xz -C "$TMP_DIR" --strip-components=1
  sudo mv "$TMP_DIR/delta" /usr/local/bin/delta
  rm -rf "$TMP_DIR"
  done_ "delta installed"
else
  done_ "delta already installed"
fi

# GitHub CLI
if ! command -v gh &>/dev/null; then
  log "Installing gh (GitHub CLI)..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list
  sudo apt-get update -qq
  sudo apt-get install -y gh
  done_ "gh installed"
else
  done_ "gh already installed"
fi

echo -e "\n${GREEN}${BOLD}[packages:extras] Done.${RESET}\n"
