#!/bin/bash
# Workspaces em Super+H/L (vim-like), janela junto com Shift.
set -e
W=org.gnome.desktop.wm.keybindings
M=org.gnome.settings-daemon.plugins.media-keys

# libera as duas ocupadas
gsettings set $W minimize "[]"
gsettings set $M screensaver "['<Super>Escape']"

# navegar entre workspaces
gsettings set $W switch-to-workspace-left  "['<Super>h']"
gsettings set $W switch-to-workspace-right "['<Super>l']"

# levar a janela junto
gsettings set $W move-to-workspace-left  "['<Super><Shift>h']"
gsettings set $W move-to-workspace-right "['<Super><Shift>l']"

echo "aplicado:"
echo "  Super+H / Super+L              -> trocar de workspace"
echo "  Super+Shift+H / Super+Shift+L  -> levar a janela junto"
echo "  Super+Escape                   -> bloquear tela"
echo "  minimize                       -> sem atalho"
