#!/bin/bash
# Restaura os padroes do GNOME para tudo que aplicar.sh mexeu
W=org.gnome.desktop.wm.keybindings
M=org.gnome.settings-daemon.plugins.media-keys
for k in minimize switch-to-workspace-left switch-to-workspace-right move-to-workspace-left move-to-workspace-right; do
  gsettings reset $W $k
done
gsettings reset $M screensaver
echo "restaurado ao padrao do GNOME"
