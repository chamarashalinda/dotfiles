#!/usr/bin/env bash
# verify.sh — Post-install health checks
# Prints pass/fail per tool and a summary. Exits non-zero if any check fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=detect.sh
source "$SCRIPT_DIR/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; DIM='\033[2m'; RESET='\033[0m'

PASS=0; FAIL=0; WARN=0

_pass() {
  local label="$1" version="${2:-}"
  local ver_str=""
  [[ -n "$version" ]] && ver_str="${DIM} (${version})${RESET}"
  printf "  ${GREEN}✔${RESET}  %-28s%b\n" "$label" "$ver_str"
  (( PASS++ )) || true
}

_fail() {
  printf "  ${RED}✘${RESET}  %-28s${RED}%s${RESET}\n" "$1" "${2:-not found}"
  (( FAIL++ )) || true
}

_warn() {
  printf "  ${YELLOW}⚠${RESET}  %-28s${YELLOW}%s${RESET}\n" "$1" "${2:-}"
  (( WARN++ )) || true
}

_check_cmd() {
  local name="$1" cmd="${2:-$1}" version_flag="${3:---version}"
  if command -v "$cmd" &>/dev/null; then
    local ver
    ver="$("$cmd" $version_flag 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+[^ ]*' | head -1 || true)"
    _pass "$name" "$ver"
  else
    _fail "$name"
  fi
}

_check_dir() {
  local name="$1" path="$2"
  if [[ -d "$path" ]]; then
    _pass "$name" "~/${path#$HOME/}"
  else
    _fail "$name" "missing: $path"
  fi
}

_check_file() {
  local name="$1" path="$2"
  if [[ -f "$path" ]]; then
    _pass "$name" "~/${path#$HOME/}"
  else
    _fail "$name" "missing: $path"
  fi
}

_check_git_config() {
  local name="$1" key="$2"
  local val
  val="$(git config --global "$key" 2>/dev/null || true)"
  if [[ -n "$val" ]]; then
    _pass "$name" "$val"
  else
    _fail "$name" "git config --global $key not set"
  fi
}

_section() {
  echo ""
  echo -e "${BOLD}${CYAN}$*${RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Running post-install verification...${RESET}"
echo -e "${DIM}$(date)  |  ${OS_TYPE}/${ARCH}${RESET}"

# ─── Shell ────────────────────────────────────────────────────────────────────
_section "Shell"
_check_cmd  "zsh"              zsh       "--version"
_check_dir  "oh-my-zsh"        "$HOME/.oh-my-zsh"
_check_file "p10k config"      "$HOME/.p10k.zsh"

# Check zsh is the default shell
if [[ "$SHELL" == *"zsh"* ]]; then
  _pass "zsh default shell" "$SHELL"
else
  _warn "zsh default shell" "current: $SHELL (run: chsh -s \$(which zsh))"
fi

# ─── Core CLI ─────────────────────────────────────────────────────────────────
_section "Core CLI"
_check_cmd "bat"       bat       "--version"
_check_cmd "eza"       eza       "--version"
_check_cmd "fzf"       fzf       "--version"
_check_cmd "ripgrep"   rg        "--version"
_check_cmd "fd"        fd        "--version"
_check_cmd "jq"        jq        "--version"
_check_cmd "yq"        yq        "--version"
_check_cmd "zoxide"    zoxide    "--version"
_check_cmd "direnv"    direnv    "--version"
_check_cmd "lazygit"   lazygit   "--version"
_check_cmd "delta"     delta     "--version"
_check_cmd "gh"        gh        "--version"
_check_cmd "tmux"      tmux      "-V"

# ─── Languages ────────────────────────────────────────────────────────────────
_section "Languages"
_check_cmd "go"        go        "version"
_check_cmd "rustc"     rustc     "--version"
_check_cmd "python3"   python3   "--version"
_check_cmd "pyenv"     pyenv     "--version"
_check_cmd "node"      node      "--version"
_check_cmd "fnm"       fnm       "--version"
_check_cmd "pnpm"      pnpm      "--version"

# ─── Cloud ────────────────────────────────────────────────────────────────────
_section "Cloud"
_check_cmd "aws"       aws       "--version"
_check_cmd "gcloud"    gcloud    "--version"
_check_cmd "kubectl"   kubectl   "version --client"
_check_cmd "helm"      helm      "version --short"
_check_cmd "terraform" terraform "--version"
_check_cmd "k9s"       k9s       "version --short"
_check_cmd "kubectx"   kubectx   "--help"
_check_cmd "stern"     stern     "--version"
_check_cmd "argocd"    argocd    "version --client --short"

# ─── Git & identity ───────────────────────────────────────────────────────────
_section "Git & Identity"
_check_cmd        "git"             git    "--version"
_check_git_config "git user.name"   "user.name"
_check_git_config "git user.email"  "user.email"
_check_file       "SSH public key"  "$HOME/.ssh/id_ed25519.pub"
_check_cmd        "gpg"             gpg    "--version"
_check_cmd        "chezmoi"         chezmoi "--version"

# SSH key permissions
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  _perms="$(stat -c '%a' "$HOME/.ssh/id_ed25519" 2>/dev/null || stat -f '%A' "$HOME/.ssh/id_ed25519" 2>/dev/null || echo "?")"
  if [[ "$_perms" == "600" ]]; then
    _pass "SSH key permissions" "600"
  else
    _warn "SSH key permissions" "expected 600, got $_perms"
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
_TOTAL=$(( PASS + FAIL + WARN ))
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
printf "  ${GREEN}✔ Passed${RESET}  %-4s  " "$PASS"
printf "  ${RED}✘ Failed${RESET}  %-4s  " "$FAIL"
printf "  ${YELLOW}⚠ Warned${RESET}  %-4s  " "$WARN"
printf "  Total  %s\n" "$_TOTAL"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

if (( FAIL > 0 )); then
  echo -e "${RED}${BOLD}Some checks failed. Re-run the relevant module to fix missing tools.${RESET}\n"
  exit 1
else
  echo -e "${GREEN}${BOLD}All checks passed.${RESET}\n"
fi
