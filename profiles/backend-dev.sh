#!/usr/bin/env bash
# profiles/backend-dev.sh — Backend Developer preset
#
# Stack: all language runtimes, minimal cloud (kubectl + container runtime), themes.

set -euo pipefail

_PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$_PROFILE_DIR/.." && pwd)}"

BOLD='\033[1m'; CYAN='\033[0;36m'; RESET='\033[0m'
_step() { echo -e "\n${BOLD}${CYAN}[$((++_STEP))/${_TOTAL}] $*${RESET}"; }
_STEP=0 _TOTAL=7

echo -e "\n${BOLD}Backend Developer${RESET}"
echo -e "Modules: shell → packages → languages(all) → cloud(minimal) → git → themes → dotfiles\n"

_step "Shell"
bash "$REPO_ROOT/modules/shell/install.sh"

_step "Packages (core)"
bash "$REPO_ROOT/modules/packages/install.sh"

_step "Languages (Go + Rust + Python + Node)"
bash "$REPO_ROOT/modules/languages/install.sh"

_step "Cloud (minimal — kubectl + container runtime)"
CLOUD_MINIMAL=1 \
  bash "$REPO_ROOT/modules/cloud/install.sh"

_step "Git"
bash "$REPO_ROOT/modules/git/install.sh"

_step "Themes"
bash "$REPO_ROOT/modules/themes/install.sh"

_step "Dotfiles"
bash "$REPO_ROOT/modules/dotfiles/install.sh"
