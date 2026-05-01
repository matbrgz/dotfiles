#!/bin/bash
# macOS Bootstrap — instala Homebrew + Brewfile + configs
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MACOS_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$(dirname "$MACOS_DIR")/configurations"

echo "──────────────────────────────────────────"
echo "  macOS Setup"
echo "──────────────────────────────────────────"

# ── Homebrew ──
if ! command -v brew &>/dev/null; then
  echo "Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✓ Homebrew já instalado"
fi

# ── Brewfile ──
echo "Instalando pacotes via Brewfile..."
brew bundle --file="$MACOS_DIR/Brewfile" --no-lock

# ── ZSH configs ──
echo "Instalando configurações zsh..."

if [[ -f "$HOME/.zshrc" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
  echo "  Backup: ~/.zshrc.bak.*"
fi

if [[ -f "$HOME/.zsh_cleanup.zsh" ]]; then
  cp "$HOME/.zsh_cleanup.zsh" "$HOME/.zsh_cleanup.zsh.bak.$(date +%s)"
  echo "  Backup: ~/.zsh_cleanup.zsh.bak.*"
fi

cp "$CONFIGS_DIR/zsh/zshrc" "$HOME/.zshrc"
cp "$CONFIGS_DIR/zsh/zsh_cleanup.zsh" "$HOME/.zsh_cleanup.zsh"
echo "✓ ZSH configurado"

# ── Git config ──
if [[ -f "$CONFIGS_DIR/git/gitconfig.txt" ]]; then
  cp "$CONFIGS_DIR/git/gitignore.txt" "$HOME/.gitignore_global"
  git config --global core.excludesfile "$HOME/.gitignore_global"
  echo "✓ Git global ignore configurado"
fi

# ── macOS defaults ──
echo "Aplicando defaults do macOS..."

# Finder: mostrar extensões
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Finder: mostrar path bar
defaults write com.apple.finder ShowPathbar -bool true
# Dock: minimizar com scale
defaults write com.apple.dock mineffect -string "scale"
# Dock: não rearranjar spaces
defaults write com.apple.dock mru-spaces -bool false
# Screenshots: salvar em ~/Downloads/screenshots
mkdir -p "$HOME/Downloads/screenshots"
defaults write com.apple.screencapture location -string "$HOME/Downloads/screenshots"
# Screenshots: formato PNG
defaults write com.apple.screencapture type -string "png"

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "✓ macOS defaults aplicados"

echo ""
echo "──────────────────────────────────────────"
echo "  Setup completo!"
echo "──────────────────────────────────────────"
