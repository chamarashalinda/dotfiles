#!/usr/bin/env bash
# modules/dotfiles/install.sh — Dotfiles management via chezmoi (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }

DOTFILES_SOURCE="$REPO_ROOT/dotfiles"

echo -e "\n${BOLD}[dotfiles] Setting up dotfiles via chezmoi...${RESET}\n"

# 1. Install chezmoi
if ! command -v chezmoi &>/dev/null; then
  log "Installing chezmoi..."
  if is_mac; then
    brew install chezmoi
  else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
  fi
  done_ "chezmoi installed"
else
  done_ "chezmoi $(chezmoi --version | awk '{print $3}') already installed"
fi

# 2. Apply dotfiles — always pass --source so chezmoi uses the repo's dotfiles/
#    directory directly, without needing ~/.local/share/chezmoi to exist.
log "Applying dotfiles from $DOTFILES_SOURCE..."
chezmoi apply --source="$DOTFILES_SOURCE" --verbose

echo ""
echo -e "  Run ${CYAN}chezmoi diff --source=\"$DOTFILES_SOURCE\"${RESET} to review pending changes."
echo -e "\n${GREEN}${BOLD}[dotfiles] Done.${RESET}\n"
