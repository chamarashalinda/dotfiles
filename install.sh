#!/usr/bin/env bash
# install.sh — Local entry point
#
# Usage (run from repo root):
#   bash install.sh [--profile <name>] [--module <name>] [--dry-run]
#
# Flags:
#   --profile <name>   profile to run (default: sre-platform)
#   --module  <name>   run a single module instead of a full profile
#   --dry-run          print what would happen, make no changes

set -euo pipefail

# ─── Colours ──────────────────────────────────────────────────────────────────
BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

# ─── Resolve repo root (works whether script is sourced or run directly) ──────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Defaults ─────────────────────────────────────────────────────────────────
PROFILE="sre-platform"
MODULE=""
DRY_RUN=false

# ─── Flag parsing ─────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)  PROFILE="${2:?'--profile requires a value'}"; shift 2 ;;
    --module)   MODULE="${2:?'--module requires a value'}";  shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: bash install.sh [--profile <name>] [--module <name>] [--dry-run]"
      echo ""
      echo "  --profile  sre-platform | backend-dev | ai-engineering | minimal"
      echo "  --module   shell | packages | languages | cloud | git | themes | security | dotfiles"
      echo "  --dry-run  show what would run, make no changes"
      exit 0
      ;;
    *) echo -e "${RED}Unknown flag: $1${RESET}" >&2; exit 1 ;;
  esac
done

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
cat <<'EOF'
  ██████╗  ██████╗ ████████╗    ███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝    ██╔════╝██║██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║       █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║       ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║       ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝       ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
  Developer Workstation Bootstrap Framework
EOF
echo -e "${RESET}"

if $DRY_RUN; then
  echo -e "${YELLOW}${BOLD}DRY RUN — no changes will be made${RESET}\n"
fi

echo -e "  Profile : ${CYAN}${PROFILE}${RESET}"
[[ -n "$MODULE" ]] && echo -e "  Module  : ${CYAN}${MODULE}${RESET}"
echo -e "  Repo    : ${CYAN}${REPO_ROOT}${RESET}"
echo ""

# ─── Dry-run: just describe what would happen ─────────────────────────────────
if $DRY_RUN; then
  echo -e "${BOLD}Steps that would run:${RESET}"
  echo ""
  if [[ -n "$MODULE" ]]; then
    echo -e "  1. Run preflight checks"
    echo -e "  2. Execute module: modules/${MODULE}/install.sh"
  else
    echo -e "  1. Run preflight checks (internet, git, disk, sudo)"
    echo -e "  2. Run profile: profiles/${PROFILE}.sh"
    echo ""
    echo -e "  Profile '${PROFILE}' module sequence:"
    case "$PROFILE" in
      sre-platform)
        echo -e "    shell → packages(+cloud) → languages(Go+Python) → cloud → git → themes → security → dotfiles" ;;
      backend-dev)
        echo -e "    shell → packages → languages(all) → cloud(minimal) → git → themes → dotfiles" ;;
      ai-engineering)
        echo -e "    shell → packages → languages(Python+Node) → cloud(minimal) → git → themes → dotfiles → AI packages" ;;
      minimal)
        echo -e "    shell → packages → git → dotfiles" ;;
    esac
  fi
  echo ""
  exit 0
fi

# ─── Sanity check ─────────────────────────────────────────────────────────────
if [[ ! -f "$REPO_ROOT/bootstrap/detect.sh" ]]; then
  echo -e "${RED}Error:${RESET} run this script from the dot-files repo root." >&2
  exit 1
fi
echo -e "${GREEN}✔${RESET} Repo root: ${REPO_ROOT}"

# ─── Bootstrap environment ────────────────────────────────────────────────────
# shellcheck source=bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

echo -e "${GREEN}✔${RESET} Detected: ${OS_TYPE}/${ARCH} (${PKG_MANAGER})"

# shellcheck source=bootstrap/preflight.sh
source "$REPO_ROOT/bootstrap/preflight.sh"

# ─── Dispatch ─────────────────────────────────────────────────────────────────
if [[ -n "$MODULE" ]]; then
  MODULE_SCRIPT="$REPO_ROOT/modules/${MODULE}/install.sh"
  if [[ ! -f "$MODULE_SCRIPT" ]]; then
    echo -e "${RED}Error:${RESET} module '${MODULE}' not found at ${MODULE_SCRIPT}" >&2
    echo ""
    echo "Available modules: shell, packages, languages, cloud, git, themes, security, dotfiles"
    exit 1
  fi
  echo -e "${CYAN}→${RESET} Running module: ${MODULE}"
  REPO_ROOT="$REPO_ROOT" bash "$MODULE_SCRIPT"
else
  REPO_ROOT="$REPO_ROOT" bash "$REPO_ROOT/bootstrap/run.sh" "$PROFILE"
fi

# ─── Success ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo -e "  Restart your terminal or run ${CYAN}exec zsh${RESET} to activate the new shell."
echo -e "  Run ${CYAN}make verify${RESET} to check all tools.\n"
