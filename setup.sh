# ---------------------------------------------------------------------
# 4. Create Symlinks & Terminal Color Configurations
# ---------------------------------------------------------------------
status_echo "Checking Configuration Symlinks & Terminal Tweaks..."
mkdir -p "$HOME/.config"

# Check if the symlink explicitly points to our dotfiles to avoid broken overwrites
link_config() {
    local source_dir="$1"
    local target_dir="$2"
    
    if [ -L "$target_dir" ] && [ "$(readlink "$target_dir")" = "$source_dir" ]; then
        echo "⏭️  [SKIP] Link already correct: $target_dir"
    else
        echo "🔗 Linking $target_dir -> $source_dir"
        rm -rf "$target_dir" 
        ln -sf "$source_dir" "$target_dir"
    fi
}

link_config "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_config "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# Force Ghostty to use Zsh directly in its configuration file
GHOSTTY_CONFIG="$DOTFILES_DIR/ghostty/config"
if [ -f "$GHOSTTY_CONFIG" ]; then
    if ! grep -q "command = /bin/zsh" "$GHOSTTY_CONFIG"; then
        echo "🐚 Enforcing Zsh execution inside Ghostty config..."
        echo "command = /bin/zsh" >> "$GHOSTTY_CONFIG"
    else
        echo "⏭️  [SKIP] Ghostty config already executes Zsh."
    fi
else
    echo "⚠️  Warning: Ghostty config file not found at $GHOSTTY_CONFIG to append shell rule."
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
