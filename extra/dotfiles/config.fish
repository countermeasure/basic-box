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
# Neither setting the $PYENV_ROOT environment variable nor adding
# $PYENV_ROOT/bin to $PATH are necessary here, because both are already done by
# bash.
pyenv init - | source

set last_date $(date +%H:%M)
function set_last_time --on-event fish_preexec
    set last_date $(date +%H:%M)
end

function run_zoxide_when_command_is_unknown --on-event fish_postexec
    set exit_code $status

    if test $exit_code -eq 0
        return
    end

    set ansi_clear '\033[0m'
    set ansi_green '\033[1;32m'
    set ansi_yellow '\033[1;33m'

    if test $exit_code -eq 127
        __zoxide_z $argv

        if test $status -eq 0
            # TODO: Trunate the PWD output to ../last/three/pathelements
            echo -e "zoxide: $ansi_green🗸 Switching to $(set_window_title)$ansi_clear"
            return
        else
            set message "$ansi_yellow💥 Exit code $status$ansi_clear"
        end

    else
        set message "$ansi_yellow💥 Exit code $exit_code$ansi_clear"
    end

    echo
    echo -e $message

    # Ring the terminal bell five times in quick succession. For a visual bell,
    # this will flash the terminal window.
    set bell \\a
    for i in (seq 1 5)
        sleep 0.1
        printf $bell
    end

    # TODO: Get last_time and current_time. Only if different, print started at
    # last_time
    echo -e "$ansi_yellow   and started at $last_date$ansi_clear"
end

# TODO: Explain that this switches on vi mode.
# https://fishshell.com/docs/current/cmds/fish_vi_key_bindings.html
# set -g fish_key_bindings fish_vi_key_bindings
# set fish_cursor_default block blink
# set -g fish_escape_delay_ms 500
