#!/usr/bin/env bash
# profiles/ai-engineering.sh — AI Engineering preset
#
# Stack: Python (primary) + Node, minimal cloud, AI/ML Python packages.

set -euo pipefail

_PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$_PROFILE_DIR/.." && pwd)}"

BOLD='\033[1m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'; RESET='\033[0m'
_step() { echo -e "\n${BOLD}${CYAN}[$((++_STEP))/${_TOTAL}] $*${RESET}"; }
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
_STEP=0 _TOTAL=8

echo -e "\n${BOLD}AI Engineering${RESET}"
echo -e "Modules: shell → packages → languages(Python+Node) → cloud(minimal) → git → themes → dotfiles → AI packages\n"

_step "Shell"
bash "$REPO_ROOT/modules/shell/install.sh"

_step "Packages (core)"
bash "$REPO_ROOT/modules/packages/install.sh"

_step "Languages (Python + Node)"
SKIP_GO=1 SKIP_RUST=1 \
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

# ─── AI / ML packages ─────────────────────────────────────────────────────────
_step "AI/ML Python packages"

_ai_pipx_install() {
  local pkg="$1"
  if ! pipx list 2>/dev/null | grep -q "$pkg"; then
    log "Installing $pkg via pipx..."
    pipx install "$pkg"
    done_ "$pkg installed"
  else
    done_ "$pkg already installed"
  fi
}

_ai_pip_install() {
  local pkg="$1"
  if ! python3 -c "import ${pkg//-/_}" &>/dev/null 2>&1; then
    log "Installing $pkg..."
    pip install --quiet "$pkg"
    done_ "$pkg installed"
  else
    done_ "$pkg already installed"
  fi
}

# LLM SDKs & frameworks
for pkg in openai anthropic; do
  _ai_pip_install "$pkg"
done

for pkg in langchain langgraph; do
  _ai_pip_install "$pkg"
done

# Vector databases
for pkg in chromadb qdrant-client; do
  _ai_pip_install "$pkg"
done

# Jupyter & interactive
for pkg in jupyter ipython; do
  _ai_pipx_install "$pkg"
done

# HuggingFace
for pkg in huggingface-hub transformers; do
  _ai_pip_install "$pkg"
done

# Ollama CLI (local LLM runner)
if ! command -v ollama &>/dev/null; then
  log "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
  done_ "Ollama installed"
else
  done_ "Ollama already installed"
fi
