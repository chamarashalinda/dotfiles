#!/usr/bin/env bash
# modules/themes/install.sh — Terminal fonts and config (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
info()  { echo -e "${YELLOW}ℹ${RESET} $*"; }

echo -e "\n${BOLD}[themes] Installing fonts and terminal configs...${RESET}\n"

# ─── Nerd Fonts ───────────────────────────────────────────────────────────────
if is_mac; then
  brew tap homebrew/cask-fonts 2>/dev/null || true
  for font in font-meslo-lg-nerd-font font-jetbrains-mono-nerd-font; do
    if ! brew list --cask "$font" &>/dev/null 2>&1; then
      log "Installing $font..."
      brew install --cask "$font"
      done_ "$font installed"
    else
      done_ "$font already installed"
    fi
  done
else
  FONTS_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONTS_DIR"

  _install_nerd_font() {
    local name="$1" archive="$2"
    local target_dir="$FONTS_DIR/$name"
    if [[ ! -d "$target_dir" ]]; then
      log "Installing Nerd Font: $name..."
      local version
      version="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
      mkdir -p "$target_dir"
      curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${archive}.tar.xz" \
        | tar -xJ -C "$target_dir"
      done_ "$name Nerd Font installed"
    else
      done_ "$name Nerd Font already installed"
    fi
  }

  _install_nerd_font "JetBrainsMono" "JetBrainsMono"
  _install_nerd_font "Meslo"         "Meslo"

  log "Refreshing font cache..."
  fc-cache -fv "$FONTS_DIR" >/dev/null
  done_ "Font cache updated"
fi

# ─── Powerlevel10k config ─────────────────────────────────────────────────────
if [[ ! -f "$HOME/.p10k.zsh" ]]; then
  log "Installing powerlevel10k config..."
  cp "$REPO_ROOT/configs/p10k/.p10k.zsh" "$HOME/.p10k.zsh"
  done_ ".p10k.zsh installed"
else
  done_ ".p10k.zsh already present"
fi

# ─── Ghostty ──────────────────────────────────────────────────────────────────
GHOSTTY_CFG_DIR="$HOME/.config/ghostty"
if [[ ! -f "$GHOSTTY_CFG_DIR/config" ]]; then
  log "Installing Ghostty config..."
  mkdir -p "$GHOSTTY_CFG_DIR"
  cp "$REPO_ROOT/configs/ghostty/config" "$GHOSTTY_CFG_DIR/config"
  done_ "Ghostty config installed → $GHOSTTY_CFG_DIR/config"
else
  done_ "Ghostty config already present"
fi

# ─── Alacritty ────────────────────────────────────────────────────────────────
ALACRITTY_CFG_DIR="$HOME/.config/alacritty"
if [[ ! -f "$ALACRITTY_CFG_DIR/alacritty.toml" ]]; then
  log "Installing Alacritty config..."
  mkdir -p "$ALACRITTY_CFG_DIR"
  cp "$REPO_ROOT/configs/alacritty/alacritty.toml" "$ALACRITTY_CFG_DIR/alacritty.toml"
  done_ "Alacritty config installed → $ALACRITTY_CFG_DIR/alacritty.toml"
else
  done_ "Alacritty config already present"
fi

# ─── tmux ─────────────────────────────────────────────────────────────────────
if [[ ! -f "$HOME/.tmux.conf" ]]; then
  log "Installing tmux config..."
  cp "$REPO_ROOT/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
  done_ "tmux config installed → ~/.tmux.conf"
else
  done_ "tmux config already present"
fi

# tmux plugin manager (tpm)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  log "Installing tmux plugin manager (tpm)..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
  done_ "tpm installed — run prefix + I inside tmux to install plugins"
else
  done_ "tpm already installed"
fi

# ─── iTerm2 ───────────────────────────────────────────────────────────────────
if is_mac; then
  info "iTerm2 profile: import manually from $REPO_ROOT/configs/iterm2/profile.json"
  info "  iTerm2 → Preferences → Profiles → Other Actions → Import JSON Profiles"
fi

echo -e "\n${GREEN}${BOLD}[themes] Done.${RESET}\n"
