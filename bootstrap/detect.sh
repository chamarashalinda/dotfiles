#!/usr/bin/env bash
# detect.sh — OS and architecture detection
#
# SOURCE this file (do not execute directly).
# Exports: OS_TYPE, OS_VERSION, OS_DISTRO, ARCH, PKG_MANAGER, IS_MAC, IS_LINUX
# Helper functions: is_mac, is_linux, is_arm, is_ubuntu, is_debian, is_fedora

set -euo pipefail

_raw_os="$(uname -s)"
case "$_raw_os" in
  Darwin)
    OS_TYPE="macos"
    OS_VERSION="$(sw_vers -productVersion)"
    IS_MAC=true
    IS_LINUX=false
    PKG_MANAGER="brew"
    OS_DISTRO=""
    ;;
  Linux)
    OS_TYPE="linux"
    OS_VERSION="$(uname -r)"
    IS_MAC=false
    IS_LINUX=true
    if [[ -f /etc/os-release ]]; then
      # shellcheck source=/dev/null
      source /etc/os-release
      OS_DISTRO="${ID:-unknown}"
    else
      OS_DISTRO="unknown"
    fi
    case "${OS_DISTRO:-}" in
      ubuntu|debian) PKG_MANAGER="apt" ;;
      fedora|rhel|centos) PKG_MANAGER="dnf" ;;
      *) PKG_MANAGER="apt" ;;
    esac
    ;;
  *)
    echo "Unsupported OS: $_raw_os" >&2
    exit 1
    ;;
esac

_raw_arch="$(uname -m)"
case "$_raw_arch" in
  x86_64)        ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "Unsupported architecture: $_raw_arch" >&2
    exit 1
    ;;
esac

export OS_TYPE OS_VERSION OS_DISTRO ARCH PKG_MANAGER IS_MAC IS_LINUX

is_mac()    { [[ "$IS_MAC"        == true ]]; }
is_linux()  { [[ "$IS_LINUX"      == true ]]; }
is_arm()    { [[ "$ARCH"          == "arm64" ]]; }
is_ubuntu() { [[ "${OS_DISTRO:-}" == "ubuntu" ]]; }
is_debian() { [[ "${OS_DISTRO:-}" == "debian" ]]; }
is_fedora() { [[ "${OS_DISTRO:-}" == "fedora" ]]; }

export -f is_mac is_linux is_arm is_ubuntu is_debian is_fedora

# Ensure Homebrew is on PATH for every script that sources this file.
# Apple Silicon installs to /opt/homebrew; Intel to /usr/local.
if [[ "$IS_MAC" == true ]]; then
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
