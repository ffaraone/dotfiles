#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

echo "Installing Oh My Zsh..."
export RUNZSH=no   # prevent auto switch during install
export KEEP_ZSHRC=yes  # don't overwrite your zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Make brew available in this session (Apple Silicon vs Intel)
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo "Homebrew already installed."
  fi
  brew update || true
}

install_iterm2_and_fonts() {
  echo "Installing iTerm2 and Nerd Fonts via Homebrew..."
  brew install --cask iterm2 || true
  brew tap homebrew/cask-fonts || true
  # Install a couple of popular Nerd Fonts (adjust as you like)
  brew install --cask font-hack-nerd-font font-fira-code-nerd-font || true
}

install_dynamic_iterm_profile() {
  echo "Installing iTerm2 dynamic profile from $DOTFILES_DIR/iterm2/ciccio.json"
  if [ -f "$DOTFILES_DIR/iterm2/ciccio.json" ]; then
    DEST_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    mkdir -p "$DEST_DIR"
    cp "$DOTFILES_DIR/iterm2/ciccio.json" "$DEST_DIR/"
    echo "Copied ciccio.json to '$DEST_DIR'. iTerm2 will pick this up next time it starts."
  else
    echo "Warning: $DOTFILES_DIR/iterm2/ciccio.json not found; skipping profile copy."
  fi
}

prompt_install() {
  local prompt_msg="$1"
  shift
  local packages=("$@")
  read -r -p "$prompt_msg [y/N]: " ans
  if [[ "$ans" =~ ^[Yy] ]]; then
    echo "Installing: ${packages[*]}"
    brew install ${packages[*]} || brew install --cask ${packages[*]} || true
  else
    echo "Skipping: ${packages[*]}"
  fi
}

# Ensure Homebrew and core items
ensure_brew
install_iterm2_and_fonts
install_dynamic_iterm_profile


# Prompt for optional tools
prompt_install "Install Kubernetes tools (k9s, kubectl, kubectx, kubens)?" k9s kubectl kubectx kubens
prompt_install "Install Azure CLI (azure-cli)?" azure-cli
prompt_install "Install AWS CLI (awscli)?" awscli


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
