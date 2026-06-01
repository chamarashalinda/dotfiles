#!/usr/bin/env bash
# profiles/minimal.sh — Minimal preset
#
# Essentials only: shell, core CLI tools, git config, dotfiles.
# No language runtimes, no cloud tooling, no themes.
# Suitable for a VM, container, or emergency workstation.

set -euo pipefail

_PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$_PROFILE_DIR/.." && pwd)}"

BOLD='\033[1m'; CYAN='\033[0;36m'; RESET='\033[0m'
_step() { echo -e "\n${BOLD}${CYAN}[$((++_STEP))/${_TOTAL}] $*${RESET}"; }
_STEP=0 _TOTAL=4

echo -e "\n${BOLD}Minimal${RESET}"
echo -e "Modules: shell → packages → git → dotfiles\n"

_step "Shell"
bash "$REPO_ROOT/modules/shell/install.sh"

_step "Packages (core)"
bash "$REPO_ROOT/modules/packages/install.sh"

_step "Git"
bash "$REPO_ROOT/modules/git/install.sh"

_step "Dotfiles"
bash "$REPO_ROOT/modules/dotfiles/install.sh"
