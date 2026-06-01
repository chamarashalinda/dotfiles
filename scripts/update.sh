#!/usr/bin/env bash
# scripts/update.sh — Update all installed tools

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'

log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
skip()  { echo -e "${YELLOW}–${RESET} Skipping $* (not installed)"; }
_has()  { command -v "$1" &>/dev/null; }

echo -e "\n${BOLD}Updating all installed tools...${RESET}\n"
_START="$(date +%s)"

# ─── OS packages ──────────────────────────────────────────────────────────────
if is_mac; then
  log "Updating Homebrew..."
  brew update
  log "Upgrading Homebrew packages..."
  brew upgrade
  log "Upgrading Homebrew casks..."
  brew upgrade --cask --greedy 2>/dev/null || true
  log "Cleaning up old Homebrew versions..."
  brew cleanup
  done_ "Homebrew packages updated"
else
  log "Updating apt packages..."
  sudo apt-get update -qq
  sudo apt-get upgrade -y
  sudo apt-get autoremove -y
  done_ "apt packages updated"
fi

# ─── Shell ────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log "Updating oh-my-zsh..."
  git -C "$HOME/.oh-my-zsh" pull --ff-only --quiet
  done_ "oh-my-zsh updated"
else
  skip "oh-my-zsh"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  log "Updating powerlevel10k..."
  git -C "$ZSH_CUSTOM/themes/powerlevel10k" pull --ff-only --quiet
  done_ "powerlevel10k updated"
else
  skip "powerlevel10k"
fi

for plugin_dir in "$ZSH_CUSTOM/plugins"/*/; do
  [[ -d "$plugin_dir/.git" ]] || continue
  plugin_name="$(basename "$plugin_dir")"
  log "Updating plugin: $plugin_name..."
  git -C "$plugin_dir" pull --ff-only --quiet
  done_ "$plugin_name updated"
done

if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  log "Updating tpm (tmux plugin manager)..."
  git -C "$HOME/.tmux/plugins/tpm" pull --ff-only --quiet
  done_ "tpm updated"
fi

# ─── Rust ─────────────────────────────────────────────────────────────────────
if _has rustup; then
  log "Updating Rust toolchain..."
  rustup update
  done_ "Rust updated"
else
  skip "rustup"
fi

# ─── Go tools ─────────────────────────────────────────────────────────────────
if _has go; then
  export GOPATH="${GOPATH:-$HOME/go}"
  export PATH="$GOPATH/bin:$PATH"
  for tool in \
    "golang.org/x/tools/gopls@latest" \
    "github.com/go-delve/delve/cmd/dlv@latest" \
    "github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; do
    name="$(basename "${tool%@*}")"
    log "Updating $name..."
    go install "$tool" 2>/dev/null && done_ "$name updated" || echo -e "  ${YELLOW}⚠${RESET} $name update failed (skipped)"
  done
else
  skip "go tools"
fi

# ─── Python / pyenv ───────────────────────────────────────────────────────────
if _has pyenv; then
  if _has pyenv-update 2>/dev/null || [[ -d "$(pyenv root)/plugins/pyenv-update" ]]; then
    log "Updating pyenv..."
    pyenv update
    done_ "pyenv updated"
  else
    log "Updating pyenv via git..."
    git -C "$(pyenv root)" pull --ff-only --quiet
    done_ "pyenv updated"
  fi
else
  skip "pyenv"
fi

if _has pipx; then
  log "Upgrading pipx packages..."
  pipx upgrade-all
  done_ "pipx packages upgraded"
else
  skip "pipx"
fi

# ─── Node / fnm ───────────────────────────────────────────────────────────────
if _has fnm; then
  log "Updating Node LTS via fnm..."
  fnm install --lts
  fnm default lts-latest
  done_ "Node LTS updated"
else
  skip "fnm"
fi

if _has npm; then
  log "Updating global npm packages..."
  npm update -g --silent
  done_ "Global npm packages updated"
else
  skip "npm"
fi

# ─── chezmoi ──────────────────────────────────────────────────────────────────
if _has chezmoi; then
  log "Upgrading chezmoi..."
  chezmoi upgrade
  done_ "chezmoi upgraded"
else
  skip "chezmoi"
fi

if _has chezmoi; then
  log "Applying latest dotfiles..."
  chezmoi apply
  done_ "Dotfiles applied"
fi

# ─── tldr ─────────────────────────────────────────────────────────────────────
if _has tldr; then
  log "Updating tldr pages..."
  tldr --update
  done_ "tldr pages updated"
else
  skip "tldr"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
_END="$(date +%s)"
_ELAPSED=$(( _END - _START ))

echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  ✔  All tools updated in ${_ELAPSED}s${RESET}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  Run ${CYAN}make verify${RESET} to confirm everything is healthy.\n"
