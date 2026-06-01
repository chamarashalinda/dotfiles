#!/usr/bin/env bash
# run.sh — Profile dispatcher
# Usage: bash run.sh <profile>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export REPO_ROOT

# shellcheck source=detect.sh
source "$SCRIPT_DIR/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

PROFILE="${1:-sre-platform}"
PROFILE_SCRIPT="$REPO_ROOT/profiles/${PROFILE}.sh"

# Validate profile exists
if [[ ! -f "$PROFILE_SCRIPT" ]]; then
  echo -e "\n${RED}Error:${RESET} profile '${PROFILE}' not found.\n"
  echo -e "Available profiles:"
  for p in "$REPO_ROOT/profiles/"*.sh; do
    echo -e "  ${CYAN}$(basename "${p%.sh}")${RESET}"
  done
  echo ""
  exit 1
fi

echo -e "\n${BOLD}${CYAN}▶ Profile: ${PROFILE}  |  ${OS_TYPE}/${ARCH}${RESET}\n"

_START="$(date +%s)"

# shellcheck source=/dev/null
source "$PROFILE_SCRIPT"

_END="$(date +%s)"
_ELAPSED=$(( _END - _START ))

echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  ✔  Profile '${PROFILE}' complete in ${_ELAPSED}s${RESET}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  Next: run ${CYAN}make verify${RESET} to confirm all tools installed."
echo -e "        Restart your terminal (or run ${CYAN}exec zsh${RESET}) to load the new shell.\n"
