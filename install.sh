#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

echo "Installing Oh My Zsh..."
export RUNZSH=no   # prevent auto switch during install
export KEEP_ZSHRC=yes  # don't overwrite your zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

echo "Ensuring ~/.config exists..."
mkdir -p "$HOME/.config"

echo "Linking dotfiles..."

# Link your .zshrc
if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
  rm -f "$HOME/.zshrc"
fi
ln -s "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

# Link starship config
if [ -f "$HOME/.config/starship.toml" ] || [ -L "$HOME/.config/starship.toml" ]; then
  rm -f "$HOME/.config/starship.toml"
fi
ln -s "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

echo "Updating plugin list in .zshrc..."
# Ensures plugins=(git docker kubectl)
sed -i.bak 's/^plugins=.*/plugins=(git docker kubectl)/' "$DOTFILES_DIR/.zshrc"

echo "Adding Starship init to .zshrc if missing..."
if ! grep -q 'eval "$(starship init zsh)"' "$DOTFILES_DIR/.zshrc"; then
  echo '' >> "$DOTFILES_DIR/.zshrc"
  echo 'eval "$(starship init zsh)"' >> "$DOTFILES_DIR/.zshrc"
fi

echo "Setup completed."
echo "Open a new terminal or run:  exec zsh"
