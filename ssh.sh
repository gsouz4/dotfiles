SSH_KEY="$HOME/.ssh/id_ed25519"

echo "Checking SSH setup..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

echo -n "❓ Generate a new SSH key for GitHub? (y/n): "
read response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -n "📧 Enter your GitHub email address: "
    read ssh_email
    
    # Generate the key pair cleanly
    ssh-keygen -t ed25519 -C "$ssh_email" -N "" -f "$SSH_KEY"
    
    # Start agent and add key
    eval "$(ssh-agent -s)"
    
    # Create or append to config safely
    touch "$HOME/.ssh/config"
    cat <<EOT >> "$HOME/.ssh/config"
Host github.com
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOT
    
    ssh-add "$SSH_KEY"

    echo ""
    echo "================================================================="
    echo "📋 COPY THIS PUBLIC KEY TO YOUR GITHUB SETTINGS:"
    echo "================================================================="
    cat "${SSH_KEY}.pub"
    echo "================================================================="
else
    echo "❌ Skipped key generation."
fi
