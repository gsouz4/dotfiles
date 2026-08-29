# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Prompt: starship (gruvbox-rainbow preset, config in ~/.config/starship.toml)
# Binary comes from mise, so this must run after mise activate (see bottom).
# Editor
export TERM="xterm-256color"
alias vim=nvim
export MANPAGER="nvim +Man!"

# gd build flags (required by some Ruby gems). brew is macOS-only here, so
# guard it -- on Linux machines every new shell would print "command not
# found: brew" seven times otherwise.
if command -v brew >/dev/null 2>&1; then
  export LDFLAGS="-L$(brew --prefix gd)/lib"
  export CPPFLAGS="-I$(brew --prefix gd)/include"
  export CFLAGS="-I$(brew --prefix gd)/include"
  export PKG_CONFIG_PATH="$(brew --prefix gd)/lib/pkgconfig"
  export C_INCLUDE_PATH="$(brew --prefix gd)/include"
  export LIBRARY_PATH="$(brew --prefix gd)/lib"
  export LD_LIBRARY_PATH="$(brew --prefix gd)/lib"
fi

# opam (OCaml)
[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null

# Secrets
[[ -f ~/.secrets/env ]] && source ~/.secrets/env

# Machine-specific config (not tracked)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# direnv
eval "$(direnv hook zsh 2>/dev/null)"
export DIRENV_LOG_FORMAT=""

# yolo mode for Claude
yolo() {
  claude --allow-dangerously-skip-permissions "$@"
}
alias pi="$HOME/.local/share/mise/installs/node/23.9.0/bin/pi"

# opencode
export PATH=$HOME/.opencode/bin:$PATH

# mise version manager
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"

# mise shims, appended so `mise activate` keeps priority and these only resolve
# what it missed. Needed because activate rewrites PATH once, when a shell
# starts: a tool installed later is invisible to any process already running,
# and to anything that never sourced a shell at all. Claude Code's gopls-lsp
# plugin spawns `gopls` directly and hits exactly that — the shim directory is a
# stable path that always resolves to the current version.
export PATH="$PATH:$HOME/.local/share/mise/shims"

[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# starship prompt. Last so nothing above (oh-my-zsh, gvm) overrides PROMPT.
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
