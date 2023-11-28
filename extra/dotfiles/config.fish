# Don't show a greeting when starting fish.
set fish_greeting

# Set the window title.
function fish_title
    set_window_title
end

# Make an escape sequence up to 500ms after the escape key is pressed.
set fish_escape_delay_ms 500

# Accept an autosuggestion and execute it with Ctrl+f.
bind \cf accept-autosuggestion execute

# Source aliases and custom functions.
source $HOME/.config/fish/fish_aliases
source $HOME/.config/fish/fish_functions

# Enable fzf keybindings.
# Auto-completion for fzf is not available for fish.
fzf_key_bindings

# Enable zoxide.
zoxide init fish | source

# Enable Starship.
starship init fish | source

# Enable direnv.
# This should appear after shell extensions that manipulate the prompt.
direnv hook fish | source

# Enable pyenv.
# Neither setting the $PYENV_ROOT environment variable not adding
# $PYENV_ROOT/bin to $PATH are unnecessary here, because both are already done
# by bash.
pyenv init - | source
