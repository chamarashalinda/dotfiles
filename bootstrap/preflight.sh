#!/usr/bin/env bash
# preflight.sh — Pre-bootstrap environment checks
#
# Run before any module installation. Exits non-zero if critical checks fail.
# Output: coloured pass/fail/warn lines, summary count at the end.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=detect.sh
source "$SCRIPT_DIR/detect.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

_pass() { echo -e "  ${GREEN}✔${RESET}  $*"; }
_fail() { echo -e "  ${RED}✘${RESET}  $*"; (( FAILURES++ )) || true; }
_warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }

FAILURES=0

echo -e "\n${BOLD}Running preflight checks...${RESET}\n"

# 1. Internet connectivity
if curl -fsSL --max-time 5 https://1.1.1.1 &>/dev/null; then
  _pass "Internet connectivity"
else
  _fail "Internet connectivity — no network access detected"
fi

# 2. git installed
if command -v git &>/dev/null; then
  _pass "git $(git --version | awk '{print $3}')"
else
  if is_mac; then
    _warn "git not found — triggering Xcode CLI tools install"
    xcode-select --install 2>/dev/null || true
  else
    _fail "git not found — run: sudo apt install git"
  fi
fi

# 3. macOS: Xcode CLI tools
if is_mac; then
  if xcode-select -p &>/dev/null 2>&1; then
    _pass "Xcode CLI tools ($(xcode-select -p))"
  else
    _warn "Xcode CLI tools not found — installing (this may take a moment)..."
    xcode-select --install 2>/dev/null || true
  fi
fi

# 4. Linux: sudo access
if is_linux; then
  if sudo -n true 2>/dev/null || sudo true 2>/dev/null; then
    _pass "sudo access"
  else
    _fail "sudo access not available"
  fi
fi

# 5. Disk space >= 5 GB free on $HOME
_free_kb=$(df -k "$HOME" | awk 'NR==2 {print $4}')
_free_gb=$(( _free_kb / 1024 / 1024 ))
if (( _free_gb >= 5 )); then
  _pass "Disk space — ${_free_gb} GB free on \$HOME"
else
  _fail "Disk space — only ${_free_gb} GB free, need ≥ 5 GB"
fi

# 6. macOS: Homebrew presence (warn only — packages module installs it)
if is_mac; then
  if command -v brew &>/dev/null; then
    _pass "Homebrew $(brew --version | head -1 | awk '{print $2}')"
  else
    _warn "Homebrew not found — will be installed by the packages module"
  fi
fi

echo ""
if (( FAILURES > 0 )); then
  echo -e "${RED}${BOLD}Preflight failed — ${FAILURES} critical check(s) did not pass.${RESET}"
  exit 1
else
  echo -e "${GREEN}${BOLD}All preflight checks passed.${RESET}\n"
fi
