#!/usr/bin/env bash
# modules/packages/install.sh — Core CLI package installation (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }

echo -e "\n${BOLD}[packages] Installing core CLI tools...${RESET}\n"

if is_mac; then
  # Install Homebrew if missing
  if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if is_arm; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    done_ "Homebrew installed"
  else
    done_ "Homebrew already installed ($(brew --version | head -1 | awk '{print $2}'))"
  fi

  log "Installing core packages from Brewfile.core..."
  brew bundle --file="$SCRIPT_DIR/Brewfile.core"
  done_ "Core packages installed"

  if [[ -n "${BREWFILE_EXTRA:-}" ]]; then
    log "Installing extra packages from $BREWFILE_EXTRA..."
    brew bundle --file="$BREWFILE_EXTRA"
    done_ "Extra packages installed"
  fi

else
  log "Updating apt package index..."
  sudo apt-get update -qq

  log "Installing core packages..."
  grep -v '^\s*#' "$SCRIPT_DIR/apt_packages.txt" | grep -v '^\s*$' \
    | xargs sudo apt-get install -y --no-install-recommends
  done_ "Core packages installed"

  log "Installing extras not available in apt..."
  bash "$SCRIPT_DIR/install_extras_linux.sh"
fi

echo -e "\n${GREEN}${BOLD}[packages] Done.${RESET}\n"
