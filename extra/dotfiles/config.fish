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

# Make the time a command starts available to the functions which run on the
# fish_postexec event in seconds since the Epoch.
function set_command_start_time --on-event fish_preexec
    set --global time_command_started (date +%s)
end

# Show how long a command took, both in the terminal and as a notification.
function show_command_duration --on-event fish_postexec
    # Work out how long the command took.
    set time_command_ended (date +%s)
    set duration_in_seconds (math $time_command_ended - $time_command_started)

    # Do nothing if the command took less than five seconds.
    if test $duration_in_seconds -lt 5
        return 0
    end

    # Get the name of the command.
    # First, if there are multiple statements, get the first one.
    set first_statement (string split ';' $argv)[1]
    # Then, get the command from the first statement, including sudo if sudo is
    # present.
    set command (string split ' ' $first_statement)[1]
    if test $command = sudo
        set command_with_sudo (string split ' ' $first_statement)[1..2]
        set command (string join ' ' $command_with_sudo)
    end

    # Do nothing for commands for which the duration is of no interest.
    set commands_to_ignore f ranger
    set command_without_sudo (string replace --regex "^sudo " "" $command)
    if contains $command_without_sudo $commands_to_ignore
        return 0
    end

    # Create a message about how long the command took.
    set seconds (math $duration_in_seconds % 60)
    set minutes (math \(floor \($duration_in_seconds / 60\)\) % 60)
    set hours (math -s0 $duration_in_seconds / 3600)
    echo
    if test $duration_in_seconds -lt 60
        set duration "$duration_in_seconds"s
    else if test $duration_in_seconds -lt 600
        set duration "$minutes"m "$seconds"s
    else if test $duration_in_seconds -lt 3600
        set duration "$minutes"m
    else
        set duration "$hours"h "$minutes"m
    end
    set duration_message "The \"$command\" command ran for $duration"

    # Print a message about how long the command took. If it took longer than
    # one minute, the message will include the command's start time, and a
    # notification matching the message will also be displayed.
    set_color --bold brblack
    if test $duration_in_seconds -lt 60
        echo "⌛ $duration_message"
    else
        set start_time (date -d @$time_command_started +%H:%M)
        set end_time (date -d @$time_command_ended +%H:%M)
        set verbose_duration_message \
            "$duration_message, from $start_time to $end_time"
        echo "⌛ $verbose_duration_message"
        set commands_to_not_notify_about box
        if not contains $command_without_sudo $commands_to_not_notify_about
            set icon_path /usr/share/icons/Adwaita/scalable
            notify-send \
                'Command completed' \
                "$verbose_duration_message." \
                --icon $icon_path/legacy/utilities-terminal-symbolic.svg
        end
    end
    set_color normal
end

# Update the prompt once a command is run to show what time it started.
function show_time_command_started --on-event fish_preexec
    # Work out how many lines the cursor has moved below the prompt.
    set command_lines_count (echo $argv | wc -l)
    if test $command_lines_count -gt 1
        set lines_cursor_has_moved $command_lines_count
    else
        set prompt_characters_count 10
        set command_characters_count (string length $argv)
        set all_characters_count \
            (math $prompt_characters_count + 1 + $command_characters_count)
        set lines_cursor_has_moved \
            (math -s0 "(1 + (($all_characters_count - 1) / $COLUMNS))")
    end
    # Save the cursor position.
    tput sc
    # Move the cursor up to the line the prompt is on if it has moved down.
    tput cuu $lines_cursor_has_moved
    # Move the cursor along the line to the start of the time placeholder.
    tput cuf 3
    # Replace the time placeholder with the current time.
    set_color --bold brblack
    echo (date +%H:%M)
    set_color normal
    # Restore the cursor position.
    tput rc
end
