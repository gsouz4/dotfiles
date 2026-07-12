#!/usr/bin/env zsh

set -e

echo "🚀 Starting Ubuntu Dev Environment Setup..."

# Helper function to print clean status messages
status_echo() {
    echo -e "\n========================================\n🔷 $1\n========================================"
}

# ---------------------------------------------------------------------
# 1. System Update, Core Dependencies (with Tmux & VSCodium) & Nerd Font
# ---------------------------------------------------------------------
status_echo "Checking System Dependencies & Open-Source VS Code..."

# Only run update if it hasn't been run in the last 24 hours
if [ -z "$(find /var/lib/apt/lists -mtime -1 -print -quit)" ]; then
    echo "🔄 Package lists are outdated. Updating..."
    sudo apt update && sudo apt upgrade -y
else
    echo "⏭️  [SKIP] Package lists are fresh."
fi

# Install VSCodium repository if not already present
if ! command -v codium &> /dev/null; then
    echo "📦 Adding VSCodium (Open-Source VS Code) Repository..."
    sudo apt install -y gnupg software-properties-common
    wget -qO - https://gitlab.com/paulcarroccio/vscodium-deb-rpm-repo/-/raw/master/pub.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/vscodium-archive-keyring.gpg > /dev/null
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /usr/share/keyrings/vscodium.list
    sudo apt update
fi

echo "📦 Ensuring core tools, tmux, and open-source code are installed..."
sudo apt install -y \
    git zsh tmux vscodium curl build-essential unzip fzf ripgrep bison \
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
    
    curl -fLo "$TEMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/ZedMono.zip"
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

mkdir -p "$HOME/.config"

link_config() {
    local source_path="$1"
    local target_path="$2"
    
    if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
        echo "⏭️  [SKIP] Link already correct: $target_path"
    else
        echo "🔗 Linking $target_path -> $source_path"
        rm -rf "$target_path"
        ln -sf "$source_path" "$target_path"
    fi
}

# NEOVIM: Point at the real config dir inside the stow package
link_config "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim"

# TMUX: Link the tmux config into the home directory
link_config "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# GHOSTTY: Explicitly maps config target
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
# 5. Install NVM, Node LTS, & Claude Code
# ---------------------------------------------------------------------
status_echo "Checking Node.js Environment (NVM) & CLIs..."

mkdir -p "$HOME/.nvm"
export NVM_DIR="$HOME/.nvm"

if [ ! -f "$NVM_DIR/nvm.sh" ]; then
    echo "🟢 Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# Explicitly guarantee NVM loader block exists inside your final .zshrc config
if ! grep -q "NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
    echo "📝 Injecting NVM initialization pathways to ~/.zshrc..."
    cat <<'EOF' >> "$HOME/.zshrc"

# Node Version Manager (NVM) Loader
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
fi

# Securely source NVM into the current script loop context
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "🟢 Ensuring Node.js LTS is configured..."
nvm install --lts
nvm use --lts --default

if ! command -v claude &> /dev/null; then
    echo "🤖 Installing official Claude Code CLI tool globally..."
    npm install -g @anthropic-ai/claude-code
else
    echo "⏭️  [SKIP] Claude Code is already installed."
fi

# ---------------------------------------------------------------------
# 6. Install Go via GVM (Forced Binary Mode Fix)
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
# 7. Install Erlang/Elixir via asdf
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
# 8. Install mise (version manager) + Neovim nightly + tree-sitter CLI
# ---------------------------------------------------------------------
# nvim-treesitter's `main` branch requires Neovim >= 0.12 (nightly) and the
# tree-sitter CLI (>= 0.26.1), neither of which apt provides. mise manages both;
# versions are tracked in tool-versions/.tool-versions.
status_echo "Checking mise & managed tools (Neovim nightly, tree-sitter)..."

if ! command -v mise &> /dev/null && [ ! -x "$HOME/.local/bin/mise" ]; then
    echo "🔧 Installing mise..."
    curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Activate mise in the shell (guarded, matches the NVM/GVM injection style)
if ! grep -q "mise activate" "$HOME/.zshrc" 2>/dev/null; then
    echo "📝 Injecting mise activation into ~/.zshrc..."
    cat <<'EOF' >> "$HOME/.zshrc"

# mise version manager
# Ensure ~/.local/bin (where mise installs itself) is on PATH before activating,
# otherwise `mise activate` fails with "command not found: mise".
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"
EOF
fi

# Point ~/.tool-versions at the tracked file so mise picks up global versions
link_config "$DOTFILES_DIR/tool-versions/.tool-versions" "$HOME/.tool-versions"

# Install only the tools this section owns. Other entries in ~/.tool-versions
# (ruby, erlang, elixir, …) stay with asdf/gvm/nvm during the mise migration.
echo "📥 Installing Neovim nightly & tree-sitter via mise..."
mise install -y neovim tree-sitter

# ---------------------------------------------------------------------
# Remove any system Neovim whose version differs from the mise-managed one.
# ---------------------------------------------------------------------
# A stale nvim (apt 0.11.x, a manual /usr/local/bin build, a snap, ...) shadows
# the mise nightly on PATH and breaks the nvim-treesitter `main` config, which
# needs >= 0.12. We take the mise nvim as the source of truth: any other nvim on
# the system with a different --version is removed so `nvim` resolves to mise's.
MISE_NVIM="$(mise which nvim 2>/dev/null || true)"
MISE_NVIM_VER=""
if [ -x "$MISE_NVIM" ]; then
    MISE_NVIM_VER="$("$MISE_NVIM" --version 2>/dev/null | head -1)"
fi

if [ -n "$MISE_NVIM_VER" ]; then
    for candidate in /usr/bin/nvim /usr/local/bin/nvim /bin/nvim /snap/bin/nvim; do
        [ -x "$candidate" ] || continue          # not present
        [ "$candidate" = "$MISE_NVIM" ] && continue  # this IS the mise binary

        candidate_ver="$("$candidate" --version 2>/dev/null | head -1)"
        [ "$candidate_ver" = "$MISE_NVIM_VER" ] && continue  # same version, keep it

        echo "🧹 Removing $candidate ($candidate_ver) — differs from mise ($MISE_NVIM_VER)"
        if dpkg -S "$candidate" >/dev/null 2>&1; then
            # apt-owned: remove the package cleanly
            sudo apt remove -y neovim
        else
            # manual install / snap symlink: drop the binary
            sudo rm -f "$candidate"
        fi
    done
    hash -r 2>/dev/null || true
    echo "🔎 Neovim now resolves to: $("$MISE_NVIM" --version | head -1)"
else
    echo "⚠️  mise could not resolve nvim; skipping system-Neovim cleanup."
fi

# ---------------------------------------------------------------------
# 9. Interactive GitHub SSH Key Setup
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

status_echo "🎉 Complete! Environment ready, tmux & VSCodium installed, Claude Code configured."
