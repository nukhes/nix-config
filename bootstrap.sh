#!/usr/bin/env bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

info "Starting NixOS configuration bootstrap..."

# --- 1. Checkups ---
info "Performing checkups..."

if [ ! -f "/etc/hostname" ]; then
    error "/etc/hostname not found. Cannot determine hostname."
    exit 1
fi
HOST=$(cat /etc/hostname)
info "Detected hostname: $HOST"

# Check for personal SSH keys
if ! ls "$HOME"/.ssh/id_* >/dev/null 2>&1; then
    warn "No SSH keys found in ~/.ssh/. You might not be able to clone via SSH."
    read -p "Press enter to continue anyway, or Ctrl+C to abort..."
fi

# Check for system SSH keys
if ! ls /etc/ssh/ssh_host_* >/dev/null 2>&1; then
    warn "No SSH host keys found in /etc/ssh/. Agenix decryption might fail."
    read -p "Press enter to continue anyway, or Ctrl+C to abort..."
fi

# --- 2. Git Clone ---
if [ -d "$HOME/.nix-config" ]; then
    warn "$HOME/.nix-config already exists. Skipping clone step."
else
    info "Cloning repository..."
    if ! command -v git >/dev/null 2>&1; then
        info "Git is not installed. Using nix-shell to provide git..."
        nix-shell -p git --run "git clone git@github.com:nukhes/nix-config.git $HOME/.nix-config"
    else
        git clone git@github.com:nukhes/nix-config.git "$HOME/.nix-config"
    fi
fi

# --- 3. NixOS Rebuild ---
info "Applying NixOS configuration for $HOST..."
cd "$HOME/.nix-config"
sudo nixos-rebuild switch --flake ".#$HOST"

info "Bootstrap successfully completed!"
