#!/usr/bin/env bash
# modules/cloud/install.sh — Cloud & DevOps toolchain (idempotent)
#
# Env vars:
#   CLOUD_MINIMAL   set to 1 to install kubectl + container runtime only
#   SKIP_AWS        set to 1 to skip AWS tooling
#   SKIP_GCP        set to 1 to skip GCP tooling
#   SKIP_TERRAFORM  set to 1 to skip Terraform tooling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../bootstrap/detect.sh
source "$REPO_ROOT/bootstrap/detect.sh"

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
log()   { echo -e "${CYAN}→${RESET} $*"; }
done_() { echo -e "${GREEN}✔${RESET} $*"; }
skip()  { echo -e "${YELLOW}–${RESET} Skipping $*"; }

CLOUD_MINIMAL="${CLOUD_MINIMAL:-0}"

echo -e "\n${BOLD}[cloud] Installing cloud & DevOps toolchain...${RESET}\n"

_gh_latest() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name": "v\?\([^"]*\)".*/\1/'
}

# ─── Containers ───────────────────────────────────────────────────────────────
if is_mac; then
  if ! command -v orbctl &>/dev/null && [[ ! -d "/Applications/OrbStack.app" ]]; then
    log "Installing OrbStack (Docker/container runtime for macOS)..."
    brew install --cask orbstack
    done_ "OrbStack installed"
  else
    done_ "OrbStack already installed"
  fi
else
  if ! command -v docker &>/dev/null; then
    log "Installing Docker CE..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "${USER}"
    done_ "Docker CE installed (log out and back in for group membership)"
  else
    done_ "Docker $(docker --version | awk '{print $3}' | tr -d ',') already installed"
  fi

  # Docker Compose plugin
  if ! docker compose version &>/dev/null 2>&1; then
    log "Installing Docker Compose plugin..."
    _arch_tag="$([ "$ARCH" = "arm64" ] && echo "aarch64" || echo "x86_64")"
    _version="$(_gh_latest docker/compose)"
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -fsSL \
      "https://github.com/docker/compose/releases/download/v${_version}/docker-compose-linux-${_arch_tag}" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    done_ "Docker Compose plugin installed"
  else
    done_ "Docker Compose plugin already installed"
  fi
fi

if [[ "$CLOUD_MINIMAL" == "1" ]]; then
  log "CLOUD_MINIMAL=1 — installing kubectl only, skipping full cloud stack"
fi

# ─── Kubernetes tools ─────────────────────────────────────────────────────────
if is_mac; then
  for tool in kubectl kubectx helm k9s stern; do
    if ! command -v "$tool" &>/dev/null; then
      log "Installing $tool..."
      brew install "$tool"
      done_ "$tool installed"
    else
      done_ "$tool already installed"
    fi
  done
else
  # kubectl
  if ! command -v kubectl &>/dev/null; then
    log "Installing kubectl..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
      | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
      | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -qq
    sudo apt-get install -y kubectl
    done_ "kubectl installed"
  else
    done_ "kubectl $(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | head -1 | cut -d'"' -f4) already installed"
  fi

  # helm
  if ! command -v helm &>/dev/null; then
    log "Installing helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    done_ "helm installed"
  else
    done_ "helm already installed"
  fi

  # kubectx + kubens
  if ! command -v kubectx &>/dev/null; then
    log "Installing kubectx/kubens..."
    _version="$(_gh_latest ahmetb/kubectx)"
    _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
    for bin in kubectx kubens; do
      curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/v${_version}/${bin}_v${_version}_linux_${_arch_tag}.tar.gz" \
        | sudo tar -xz -C /usr/local/bin "$bin"
    done
    done_ "kubectx/kubens installed"
  else
    done_ "kubectx already installed"
  fi

  # k9s
  if ! command -v k9s &>/dev/null; then
    log "Installing k9s..."
    _version="$(_gh_latest derailed/k9s)"
    _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
    _url="https://github.com/derailed/k9s/releases/download/v${_version}/k9s_Linux_${_arch_tag}.tar.gz"
    TMP_DIR="$(mktemp -d)"
    curl -fsSL "$_url" | tar -xz -C "$TMP_DIR"
    sudo mv "$TMP_DIR/k9s" /usr/local/bin/k9s
    rm -rf "$TMP_DIR"
    done_ "k9s installed"
  else
    done_ "k9s already installed"
  fi

  # stern
  if ! command -v stern &>/dev/null; then
    log "Installing stern..."
    _version="$(_gh_latest stern/stern)"
    _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
    _url="https://github.com/stern/stern/releases/download/v${_version}/stern_${_version}_linux_${_arch_tag}.tar.gz"
    TMP_DIR="$(mktemp -d)"
    curl -fsSL "$_url" | tar -xz -C "$TMP_DIR"
    sudo mv "$TMP_DIR/stern" /usr/local/bin/stern
    rm -rf "$TMP_DIR"
    done_ "stern installed"
  else
    done_ "stern already installed"
  fi
fi

if [[ "$CLOUD_MINIMAL" == "1" ]]; then
  echo -e "\n${GREEN}${BOLD}[cloud] Done (minimal).${RESET}\n"
  exit 0
fi

# ─── AWS ──────────────────────────────────────────────────────────────────────
if [[ "${SKIP_AWS:-0}" == "1" ]]; then
  skip "AWS tooling"
else
  if ! command -v aws &>/dev/null; then
    log "Installing AWS CLI v2..."
    if is_mac; then
      brew install awscli
    else
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "aarch64" || echo "x86_64")"
      TMP_DIR="$(mktemp -d)"
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${_arch_tag}.zip" -o "$TMP_DIR/awscliv2.zip"
      unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
      sudo "$TMP_DIR/aws/install"
      rm -rf "$TMP_DIR"
    fi
    done_ "AWS CLI $(aws --version 2>&1 | awk '{print $1}') installed"
  else
    done_ "AWS CLI already installed"
  fi

  # aws-vault
  if ! command -v aws-vault &>/dev/null; then
    log "Installing aws-vault..."
    if is_mac; then
      brew install --cask aws-vault
    else
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
      _version="$(_gh_latest 99designs/aws-vault)"
      curl -fsSL "https://github.com/99designs/aws-vault/releases/download/v${_version}/aws-vault-linux-${_arch_tag}" \
        | sudo tee /usr/local/bin/aws-vault >/dev/null
      sudo chmod +x /usr/local/bin/aws-vault
    fi
    done_ "aws-vault installed"
  else
    done_ "aws-vault already installed"
  fi

  # Session Manager plugin
  if ! command -v session-manager-plugin &>/dev/null; then
    log "Installing AWS Session Manager plugin..."
    if is_mac; then
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "intel")"
      curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_${_arch_tag}/sessionmanager-bundle.zip" \
        -o /tmp/sessionmanager-bundle.zip
      unzip -q /tmp/sessionmanager-bundle.zip -d /tmp/sessionmanager-bundle
      sudo /tmp/sessionmanager-bundle/sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
      rm -rf /tmp/sessionmanager-bundle*
    else
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "ubuntu_64bit")"
      curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${_arch_tag}/session-manager-plugin.deb" \
        -o /tmp/session-manager-plugin.deb
      sudo dpkg -i /tmp/session-manager-plugin.deb
      rm /tmp/session-manager-plugin.deb
    fi
    done_ "Session Manager plugin installed"
  else
    done_ "Session Manager plugin already installed"
  fi
fi

# ─── GCP ──────────────────────────────────────────────────────────────────────
if [[ "${SKIP_GCP:-0}" == "1" ]]; then
  skip "GCP tooling"
else
  if ! command -v gcloud &>/dev/null; then
    log "Installing Google Cloud SDK..."
    if is_mac; then
      brew install --cask google-cloud-sdk
    else
      echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
      curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
      sudo apt-get update -qq
      sudo apt-get install -y google-cloud-sdk
    fi
    done_ "gcloud SDK installed"
  else
    done_ "gcloud $(gcloud --version 2>/dev/null | head -1 | awk '{print $4}') already installed"
  fi

  if ! gcloud components list --filter="state.name=Installed" 2>/dev/null | grep -q "gke-gcloud-auth-plugin"; then
    log "Installing gke-gcloud-auth-plugin..."
    if is_mac; then
      gcloud components install gke-gcloud-auth-plugin --quiet 2>/dev/null || \
        brew install google-cloud-sdk  # fallback for managed installs
    else
      sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
    fi
    done_ "gke-gcloud-auth-plugin installed"
  else
    done_ "gke-gcloud-auth-plugin already installed"
  fi
fi

# ─── Terraform ────────────────────────────────────────────────────────────────
if [[ "${SKIP_TERRAFORM:-0}" == "1" ]]; then
  skip "Terraform tooling"
else
  # tfenv for version management
  if ! command -v tfenv &>/dev/null; then
    log "Installing tfenv..."
    if is_mac; then
      brew install tfenv
    else
      git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
      sudo ln -sf "$HOME/.tfenv/bin/tfenv"    /usr/local/bin/tfenv
      sudo ln -sf "$HOME/.tfenv/bin/terraform" /usr/local/bin/terraform
    fi
    done_ "tfenv installed"
  else
    done_ "tfenv already installed"
  fi

  if ! tfenv list 2>/dev/null | grep -q '\*'; then
    log "Installing latest Terraform via tfenv..."
    tfenv install latest
    tfenv use latest
    done_ "Terraform $(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4) installed"
  else
    done_ "Terraform already managed by tfenv"
  fi

  # terragrunt
  if ! command -v terragrunt &>/dev/null; then
    log "Installing terragrunt..."
    if is_mac; then
      brew install terragrunt
    else
      _version="$(_gh_latest gruntwork-io/terragrunt)"
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
      curl -fsSL "https://github.com/gruntwork-io/terragrunt/releases/download/v${_version}/terragrunt_linux_${_arch_tag}" \
        | sudo tee /usr/local/bin/terragrunt >/dev/null
      sudo chmod +x /usr/local/bin/terragrunt
    fi
    done_ "terragrunt installed"
  else
    done_ "terragrunt already installed"
  fi


  # terraform-docs
  if ! command -v terraform-docs &>/dev/null; then
    log "Installing terraform-docs..."
    if is_mac; then
      brew install terraform-docs
    else
      _version="$(_gh_latest terraform-docs/terraform-docs)"
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
      curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${_version}/terraform-docs-v${_version}-linux-${_arch_tag}.tar.gz" \
        | sudo tar -xz -C /usr/local/bin terraform-docs
    fi
    done_ "terraform-docs installed"
  else
    done_ "terraform-docs already installed"
  fi

  # argocd CLI
  if ! command -v argocd &>/dev/null; then
    log "Installing argocd CLI..."
    if is_mac; then
      brew install argocd
    else
      _arch_tag="$([ "$ARCH" = "arm64" ] && echo "arm64" || echo "amd64")"
      curl -fsSL "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${_arch_tag}" \
        | sudo tee /usr/local/bin/argocd >/dev/null
      sudo chmod +x /usr/local/bin/argocd
    fi
    done_ "argocd CLI installed"
  else
    done_ "argocd already installed"
  fi
fi

echo -e "\n${GREEN}${BOLD}[cloud] Done.${RESET}\n"
