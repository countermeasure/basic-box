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

# Handle commands which exit with a non-zero exit code.
function handle_non_zero_exit_code --on-event fish_postexec
    # Cache the exit code of the command that was just run, because the $status
    # variable is updated with every command that runs in this function.
    set exit_code $status

    # Do nothing and return if the exit code is zero.
    if test $exit_code -eq 0
        return 0
    end

    # If what was entered was not a recognised command, see if zoxide can
    # resolve it to a directory. A 127 exit code means the command was not
    # found.
    if test $exit_code -eq 127
        set stripped_command (string trim $argv)
        __zoxide_z (string split ' ' $stripped_command)
        set exit_code $status
        # $status is now the exit code of the __zoxide_z command.
        # If zoxide doesn't find a match, its exit code is 1, but we want the
        # exit code to be 127, because what that actually means is that the
        # command wasn't found.
        if test $exit_code -eq 1
            set exit_code 127
        end
    end

    # If the exit code is still non-zero at this point in the function, show a
    # message describing it and ring the bell.
    if test $exit_code -ne 0
        echo

        # Show a message describing the error.
        set_color --bold red
        set icon '💥'
        switch $exit_code
            case 127
                echo "$icon \"$argv\" not found as a command or directory"
            case 130
                echo "$icon Command interrupted"
            case "*"
                echo "$icon Error code $exit_code"
        end
        set_color normal

        # Ring the bell five times in quick succession. For a visual bell, this
        # will flash the window.
        for i in (seq 1 5)
            sleep 0.1
            tput bel
        end
    end
end

# Stop the default message when a command is not found being displayed by
# making this a noop.
function fish_command_not_found
end
