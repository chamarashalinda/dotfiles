# Makefile — Developer Workstation Bootstrap Framework

PROFILE      ?= sre-platform
DOTFILES_DIR ?= $(shell pwd)

BOLD  := \033[1m
CYAN  := \033[0;36m
GREEN := \033[0;32m
RESET := \033[0m

.PHONY: help bootstrap \
        shell packages languages cloud git dotfiles themes security \
        profile-sre profile-backend profile-ai profile-minimal \
        verify update chezmoi-apply chezmoi-diff clean

## help: Print all available targets
help:
	@printf "\n$(BOLD)$(CYAN)Developer Workstation Bootstrap Framework$(RESET)\n\n"
	@grep -E '^## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ": "}; {sub(/^## /, "", $$1); printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@printf "\n$(BOLD)Variables:$(RESET)\n"
	@printf "  PROFILE      current: $(PROFILE)\n"
	@printf "  DOTFILES_DIR current: $(DOTFILES_DIR)\n\n"

## bootstrap: Full bootstrap — preflight + run profile
bootstrap:
	@bash bootstrap/preflight.sh
	@bash bootstrap/run.sh $(PROFILE)

## shell: Install zsh + oh-my-zsh + powerlevel10k + plugins
shell:
	@bash modules/shell/install.sh

## packages: Install core CLI tools via brew/apt
packages:
	@bash modules/packages/install.sh

## languages: Install Go, Rust, Python, Node
languages:
	@bash modules/languages/install.sh

## cloud: Install AWS, GCP, kubectl, helm, terraform, k9s
cloud:
	@bash modules/cloud/install.sh

## git: Configure git, SSH keys, GPG
git:
	@bash modules/git/install.sh

## dotfiles: Apply dotfiles via chezmoi
dotfiles:
	@bash modules/dotfiles/install.sh

## themes: Install Nerd Fonts and terminal profiles
themes:
	@bash modules/themes/install.sh

## security: SSH hardening, Vault CLI, direnv, sops
security:
	@bash modules/security/install.sh

## profile-sre: Bootstrap SRE / Platform Engineering profile
profile-sre:
	@$(MAKE) bootstrap PROFILE=sre-platform

## profile-backend: Bootstrap Backend Developer profile
profile-backend:
	@$(MAKE) bootstrap PROFILE=backend-dev

## profile-ai: Bootstrap AI Engineering profile
profile-ai:
	@$(MAKE) bootstrap PROFILE=ai-engineering

## profile-minimal: Bootstrap Minimal profile
profile-minimal:
	@$(MAKE) bootstrap PROFILE=minimal

## verify: Run post-install health checks
verify:
	@bash bootstrap/verify.sh

## update: Update all installed tools
update:
	@bash scripts/update.sh

## chezmoi-apply: Apply dotfiles with verbose output
chezmoi-apply:
	@chezmoi apply --verbose

## chezmoi-diff: Show pending dotfile changes
chezmoi-diff:
	@chezmoi diff

## clean: Remove log and temp files
clean:
	@find . -name "*.log" -delete
	@find . -name "*.tmp" -delete
	@printf "$(GREEN)Cleaned.$(RESET)\n"
