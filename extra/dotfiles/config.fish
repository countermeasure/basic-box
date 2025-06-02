# Don't show a greeting when starting fish.
set fish_greeting

# Set the window title to the truncated current working directory.
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

# Sort fzf lists from the top down.
set --export --global FZF_DEFAULT_OPTS --reverse

# Have fzf use fd as the default source.
set --export --global FZF_DEFAULT_COMMAND 'fd --type file'

# Have fzf use fd as the source source for Ctrl-t.
set --export --global FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# Colourise man pages by setting bat as the man pager.
set --export --global MANPAGER 'sh -c "col -bx | bat -l man -p"'

# Share JupyterLab user settings across all JupyterLab environments. Without
# this, each JupyterLab installation in each virtual environment will have its
# own user settings.
set --export --global \
    JUPYTERLAB_SETTINGS_DIR "$HOME/.jupyter/lab/user-settings"

# Enable zoxide.
zoxide init fish | source

# Enable Starship.
starship init fish | source

# Enable direnv.
# This should appear after shell extensions that manipulate the prompt.
direnv hook fish | source

# Don't show direnv messages when changing directory.
set --export --global DIRENV_LOG_FORMAT

# Enable pyenv.
pyenv init - fish | source
set --export --global PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
