#!/usr/bin/env bash
# modules/shell/install.sh — Shell environment setup (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }

echo -e "\n${BOLD}[shell] Setting up shell environment...${RESET}\n"

# 1. Install zsh
if ! command -v zsh &>/dev/null; then
  log "Installing zsh..."
  if is_mac; then
    brew install zsh
  else
    sudo apt-get install -y zsh
  fi
else
  done_ "zsh $(zsh --version | awk '{print $2}') already installed"
fi

# 2. Set zsh as default shell
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  log "Setting zsh as default shell..."
  if ! grep -qF "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi
  chsh -s "$ZSH_PATH"
  done_ "Default shell → $ZSH_PATH"
else
  done_ "zsh is already the default shell"
fi

# 3. Install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  done_ "oh-my-zsh installed"
else
  done_ "oh-my-zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 4. Install powerlevel10k
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  log "Installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
  done_ "powerlevel10k installed"
else
  done_ "powerlevel10k already installed"
fi

# 5. Install zsh plugins
_install_plugin() {
  local name="$1" url="$2"
  local target="$ZSH_CUSTOM/plugins/$name"
  if [[ ! -d "$target" ]]; then
    log "Installing plugin: $name..."
    git clone --depth=1 "$url" "$target"
    done_ "$name installed"
  else
    done_ "$name already installed"
  fi
}

_install_plugin "zsh-autosuggestions"          "https://github.com/zsh-users/zsh-autosuggestions"
_install_plugin "zsh-syntax-highlighting"      "https://github.com/zsh-users/zsh-syntax-highlighting"
_install_plugin "zsh-completions"              "https://github.com/zsh-users/zsh-completions"
_install_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"

# 6. Apply dotfiles (prefer chezmoi; fall back to direct copy)
if command -v chezmoi &>/dev/null; then
  log "Applying dotfiles via chezmoi..."
  chezmoi apply --source="$REPO_ROOT/dotfiles"
else
  if [[ ! -f "$HOME/.zshrc" ]]; then
    log "Copying .zshrc (chezmoi not available)..."
    # Strip chezmoi template directives ({{ ... }} lines) — zsh can't parse them.
    grep -v '^{{.*}}$' "$REPO_ROOT/dotfiles/dot_zshrc.tmpl" > "$HOME/.zshrc"
    done_ ".zshrc copied"
  else
    done_ ".zshrc already present"
  fi
fi

# 7. Install p10k config
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
  log "Installing powerlevel10k config..."
  cp "$REPO_ROOT/configs/p10k/.p10k.zsh" "$HOME/.p10k.zsh"
  done_ ".p10k.zsh installed"
else
  done_ ".p10k.zsh already present"
fi

echo -e "\n${GREEN}${BOLD}[shell] Done.${RESET}\n"
