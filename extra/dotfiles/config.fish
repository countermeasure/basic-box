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
        # TODO: Work out how to stop all output from z, even when there's a
        # failure to find a directory to move to.
        set stripped_command (string trim $argv[1])
        __zoxide_z $stripped_command
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

# TODO: Update this comment.
# Make the time a command starts available to the functions which run on the
# fish_postexec event in seconds since the Epoch.
function set_command_start_time --on-event fish_preexec
    set --global time_command_started (date +%s)

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

    tput sc
    tput cuu $lines_cursor_has_moved
    tput cuf 3
    set_color --bold brblack
    echo (date +%H:%M)
    set_color normal
    tput rc
end

# TODO: Heading
function show_command_duration --on-event fish_postexec
    set command (string split ' ' $argv)[1]

    # Exclude commands for which the duration is of no interest.
    set commands_to_ignore f
    if contains $command $commands_to_ignore
        return 0
    end

    set time_command_ended (date +%s)
    set duration_in_seconds (math $time_command_ended - $time_command_started)
    if test $duration_in_seconds -gt 5
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
        set_color --bold brblack
        set start_time (date -d @$time_command_started +%H:%M)
        set duration_message "⌛ The \"$command\" command took $duration"
        if test $duration_in_seconds -lt 60
            echo "$duration_message"
        else
            echo "$duration_message, starting at $start_time"
            # TODO: Add an icon to the notification.
            notify-send \
                "\"$command\" command completed" \
                "The command took $duration, starting at $start_time"
        end
        set_color normal
    end
end

# TODO: Explain that this switches on vi mode.
# https://fishshell.com/docs/current/cmds/fish_vi_key_bindings.html
# set -g fish_key_bindings fish_vi_key_bindings
# set fish_cursor_default block blink
# set -g fish_escape_delay_ms 500
