#!/usr/bin/env bash
# profiles/sre-platform.sh — SRE / Platform Engineering preset
#
# Stack: full cloud toolchain, Go + Python, security hardening, all themes.

set -euo pipefail

# Resolve REPO_ROOT for standalone execution (run.sh sets it when sourcing)
_PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$_PROFILE_DIR/.." && pwd)}"

BOLD='\033[1m'; CYAN='\033[0;36m'; RESET='\033[0m'
_step() { echo -e "\n${BOLD}${CYAN}[$((++_STEP))/${_TOTAL}] $*${RESET}"; }
_STEP=0 _TOTAL=8

echo -e "\n${BOLD}SRE / Platform Engineering${RESET}"
echo -e "Modules: shell → packages+cloud → languages(Go+Python) → cloud → git → themes → security → dotfiles\n"

_step "Shell"
bash "$REPO_ROOT/modules/shell/install.sh"

_step "Packages (core + cloud)"
BREWFILE_EXTRA="$REPO_ROOT/modules/packages/Brewfile.cloud" \
  bash "$REPO_ROOT/modules/packages/install.sh"

_step "Languages (Go + Python)"
SKIP_RUST=1 SKIP_NODE=1 \
  bash "$REPO_ROOT/modules/languages/install.sh"

_step "Cloud toolchain (full)"
bash "$REPO_ROOT/modules/cloud/install.sh"

_step "Git"
bash "$REPO_ROOT/modules/git/install.sh"

_step "Themes"
bash "$REPO_ROOT/modules/themes/install.sh"

_step "Security"
bash "$REPO_ROOT/modules/security/install.sh"

_step "Dotfiles"
bash "$REPO_ROOT/modules/dotfiles/install.sh"
