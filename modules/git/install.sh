#!/usr/bin/env bash
# modules/git/install.sh — Git, SSH, and GPG configuration (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
info()  { echo -e "${YELLOW}ℹ${RESET} $*"; }

echo -e "\n${BOLD}[git] Configuring git, SSH, and GPG...${RESET}\n"

# --- Git user identity ---
_git_set_if_empty() {
  local key="$1" val="$2"
  if [[ -z "$(git config --global "$key" 2>/dev/null || true)" ]]; then
    git config --global "$key" "$val"
  fi
}

if [[ -z "${GIT_USER_NAME:-}" ]]; then
  _existing="$(git config --global user.name 2>/dev/null || true)"
  if [[ -n "$_existing" ]]; then
    GIT_USER_NAME="$_existing"
  else
    read -r -p "  Enter your git user name: " GIT_USER_NAME
  fi
fi

if [[ -z "${GIT_USER_EMAIL:-}" ]]; then
  _existing="$(git config --global user.email 2>/dev/null || true)"
  if [[ -n "$_existing" ]]; then
    GIT_USER_EMAIL="$_existing"
  else
    read -r -p "  Enter your git email: " GIT_USER_EMAIL
  fi
fi

git config --global user.name  "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
done_ "git identity: $GIT_USER_NAME <$GIT_USER_EMAIL>"

# --- Core settings ---
_EDITOR="$(command -v nvim 2>/dev/null || command -v vim || echo "vi")"
_git_set_if_empty core.editor       "$_EDITOR"
_git_set_if_empty pull.rebase       true
_git_set_if_empty init.defaultBranch main
_git_set_if_empty core.autocrlf     input
_git_set_if_empty push.autoSetupRemote true
_git_set_if_empty fetch.prune       true
done_ "git core settings applied"

# --- Aliases ---
git config --global alias.st       "status -sb"
git config --global alias.lg       "log --oneline --graph --decorate --all"
git config --global alias.co       "checkout"
git config --global alias.br       "branch"
git config --global alias.cp       "cherry-pick"
git config --global alias.unstage  "reset HEAD --"
git config --global alias.last     "log -1 HEAD"
git config --global alias.wip      "commit -am 'wip'"
done_ "git aliases configured"

# --- Multi-profile stubs ---
for scope in work personal; do
  stub="$HOME/.gitconfig-${scope}"
  dir="$HOME/${scope}"
  if [[ ! -f "$stub" ]]; then
    mkdir -p "$dir"
    cat > "$stub" <<EOF
[user]
	name  = $GIT_USER_NAME
	email = # TODO: set your ${scope} email here
EOF
    git config --global "includeIf.gitdir:${dir}/.path" ".gitconfig-${scope}"
    done_ ".gitconfig-${scope} stub created (edit to set ${scope} email)"
  else
    done_ ".gitconfig-${scope} already present"
  fi
done

# --- SSH key ---
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/id_ed25519"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$KEY_PATH" ]]; then
  log "Generating SSH key (ed25519)..."
  ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$KEY_PATH" -N ""
  chmod 600 "$KEY_PATH" "$KEY_PATH.pub"
  done_ "SSH key generated"

  eval "$(ssh-agent -s)" >/dev/null
  ssh-add "$KEY_PATH"

  echo ""
  info "Add this public key to GitHub → https://github.com/settings/keys"
  echo ""
  cat "$KEY_PATH.pub"
  echo ""
else
  done_ "SSH key already exists at $KEY_PATH"
fi

# --- SSH config hardening ---
SSH_CONFIG="$SSH_DIR/config"
if [[ ! -f "$SSH_CONFIG" ]]; then
  log "Writing SSH client config..."
  if command -v chezmoi &>/dev/null; then
    chezmoi apply --source="$REPO_ROOT/dotfiles"
  else
    install -m 600 "$REPO_ROOT/dotfiles/private_dot_ssh/config.tmpl" "$SSH_CONFIG"
    done_ "SSH config applied from template"
  fi
else
  done_ "SSH config already present"
fi

# --- GPG ---
if ! command -v gpg &>/dev/null; then
  log "Installing gnupg..."
  if is_mac; then
    brew install gnupg
  else
    sudo apt-get install -y gnupg
  fi
fi

if [[ -n "${GPG_KEY_ID:-}" ]]; then
  git config --global user.signingkey  "$GPG_KEY_ID"
  git config --global commit.gpgsign   true
  git config --global tag.gpgsign      true
  done_ "GPG signing configured (key: $GPG_KEY_ID)"
else
  info "GPG_KEY_ID not set — commit signing skipped (export GPG_KEY_ID to enable)"
fi

echo -e "\n${GREEN}${BOLD}[git] Done.${RESET}\n"
