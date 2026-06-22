#!/usr/bin/env zsh

set -e

echo "🚀 Starting Ubuntu Dev Environment Setup..."

# Helper function to print clean status messages
status_echo() {
    echo -e "\n========================================\n🔷 $1\n========================================"
}

# ---------------------------------------------------------------------
# 1. System Update, Core Dependencies & Nerd Font Installation
# ---------------------------------------------------------------------
status_echo "Checking System Dependencies..."

# Only run update if it hasn't been run in the last 24 hours
if [ -z "$(find /var/lib/apt/lists -mtime -1 -print -quit)" ]; then
    echo "🔄 Package lists are outdated. Updating..."
    sudo apt update && sudo apt upgrade -y
else
    echo "⏭️  [SKIP] Package lists are fresh."
fi

echo "📦 Ensuring core tools are installed..."
sudo apt install -y \
    git zsh neovim curl build-essential unzip fzf ripgrep bison \
    libssl-dev ncurses-dev libncurses5-dev autoconf m4 \
    libwxgtk3.2-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev \
    libssh-dev unixodbc-dev fontconfig

# --- Font Installation Block ---
echo "🔤 Checking ZedMono Nerd Font installation..."
FONT_DIR="$HOME/.local/share/fonts/ZedMono"
if [ ! -d "$FONT_DIR" ] || [ -z "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
    echo "📥 Downloading and installing ZedMono Nerd Font..."
    mkdir -p "$FONT_DIR"
    TEMP_ZIP=$(mktemp)
    
    # Fetch the latest bundled archive release directly from ryanoasis/nerd-fonts
    curl -fLo "$TEMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/ZedMono.zip"
    
    # Extract only the Propo (Proportional Alternative Layout) variations safely
    unzip -o "$TEMP_ZIP" "*Propo*" -d "$FONT_DIR"
    rm -f "$TEMP_ZIP"
    
    echo "🔄 Rebuilding system font cache profiles..."
    fc-cache -fv > /dev/null
    echo "✅ ZedMono Nerd Font Propo variants matching successfully registered!"
else
    echo "⏭️  [SKIP] ZedMono Nerd Font directory already verified."
fi

# ---------------------------------------------------------------------
# 2. Oh My Zsh Installation
# ---------------------------------------------------------------------
status_echo "Checking Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🦁 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "⏭️  [SKIP] Oh My Zsh is already installed."
fi

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔄 Changing default shell to Zsh..."
    sudo chsh -s "$(which zsh)" "$USER"
else
    echo "⏭️  [SKIP] Default shell is already Zsh."
fi

# ---------------------------------------------------------------------
# 3. Clone Dotfiles Repo
# ---------------------------------------------------------------------
status_echo "Checking Dotfiles Repository..."
DOTFILES_DIR="$HOME/Documents/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📂 Cloning dotfiles repository..."
    mkdir -p "$HOME/Documents"
    git clone https://github.com/gsouz4/dotfiles "$DOTFILES_DIR"
else
    echo "⏭️  [SKIP] Dotfiles repo already exists at $DOTFILES_DIR"
    cd "$DOTFILES_DIR" && git pull && cd - > /dev/null
fi

# ---------------------------------------------------------------------
# 4. Create Symlinks & Terminal Color Configurations
# ---------------------------------------------------------------------
status_echo "Checking Configuration Symlinks & Terminal Tweaks..."

# Create parent configuration target directories
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/ghostty"

link_config() {
    local source_path="$1"
    local target_path="$2"
    
    if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
        echo "⏭️  [SKIP] Link already correct: $target_path"
    else
        echo "🔗 Linking $target_path -> $source_path"
        rm -rf "$target_path" # Erase broken items or unexpected folders
        ln -sf "$source_path" "$target_path"
    fi
}

# NEVIM: Links the entire configuration folder layout
link_config "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# GHOSTTY: Direct file link mapping config.ghostty to the required target filename 'config'
link_config "$DOTFILES_DIR/ghostty/config.ghostty" "$HOME/.config/ghostty/config"

# Force Ghostty to use Zsh directly inside its config asset
GHOSTTY_TARGET="$DOTFILES_DIR/ghostty/config.ghostty"
if [ -f "$GHOSTTY_TARGET" ]; then
    if ! grep -q "command = /bin/zsh" "$GHOSTTY_TARGET"; then
        echo "🐚 Enforcing Zsh execution inside Ghostty repository asset..."
        echo -e "\n# Shell Rule Forced by Bootstrap\ncommand = /bin/zsh" >> "$GHOSTTY_TARGET"
    fi
fi

# Append color-enforcing environment configuration to .zshrc if not present
if ! grep -q "xterm-256color" "$HOME/.zshrc" 2>/dev/null; then
    echo "🎨 Appending color configuration fixes to ~/.zshrc..."
    cat <<'EOF' >> "$HOME/.zshrc"

# Ghostty Color & Environment Tweaks
export TERM=xterm-256color
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
EOF
fi

# ---------------------------------------------------------------------
# 5. Install Go via GVM (Forced Binary Mode Fix)
# ---------------------------------------------------------------------
status_echo "Checking GVM & Go..."
if [ ! -d "$HOME/.gvm" ]; then
    echo "🐹 Installing GVM..."
    bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
else
    echo "⏭️  [SKIP] GVM is already installed."
fi

source "$HOME/.gvm/scripts/gvm"

LATEST_GO=$(curl -s https://go.dev/VERSION?m=text | head -n 1)
if ! gvm list | grep -q "$LATEST_GO"; then
    echo "📥 Installing Go $LATEST_GO via pre-compiled binary..."
    gvm install "$LATEST_GO" -B
    gvm use "$LATEST_GO" --default
else
    echo "⏭️  [SKIP] Go $LATEST_GO is already the active version."
fi

# ---------------------------------------------------------------------
# 6. Install Erlang/Elixir via asdf
# ---------------------------------------------------------------------
status_echo "Checking asdf & Languages..."
if [ ! -d "$HOME/.asdf" ]; then
    echo "💧 Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.1
else
    echo "⏭️  [SKIP] asdf framework is already installed."
fi

source "$HOME/.asdf/asdf.sh"

asdf plugin add erlang || true
asdf plugin add elixir || true

if ! asdf list erlang 2>&1 | grep -q "no version installed"; then
    echo "⏭️  [SKIP] Erlang is already installed via asdf."
else
    echo "🏗️ Compiling latest Erlang..."
    asdf install erlang latest
    asdf global erlang latest
fi

if ! asdf list elixir 2>&1 | grep -q "no version installed"; then
    echo "⏭️  [SKIP] Elixir is already installed via asdf."
else
    echo "🏗️ Installing latest Elixir..."
    asdf install elixir latest
    asdf global elixir latest
fi

# ---------------------------------------------------------------------
# 7. Interactive GitHub SSH Key Setup
# ---------------------------------------------------------------------
status_echo "Checking GitHub SSH Setup..."
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    echo "⏭️  [SKIP] SSH Key already exists at $SSH_KEY"
else
    echo -n "❓ No SSH Key found. Generate a new one for GitHub? (y/n): "
    read -r response
    echo ""
    
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        echo -n "Enter your GitHub email address: "
        read -r ssh_email
        
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        ssh-keygen -t ed25519 -C "$ssh_email" -N "" -f "$SSH_KEY"
        eval "$(ssh-agent -s)"
        
        cat <<EOT >> "$HOME/.ssh/config"
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOT
        ssh-add "$SSH_KEY"

        echo ""
        echo "================================================================="
        echo "📋 COPY THE PUBLIC KEY BELOW TO YOUR GITHUB SETTINGS:"
        echo "================================================================="
        cat "${SSH_KEY}.pub"
        echo "================================================================="
        echo ""
        echo -n "Press [Enter] once you have added it to GitHub to complete setup..."
        read -r
    fi
fi

status_echo "🎉 Complete! Your dev environment is up-to-date, fonts registered, and fully configured."
