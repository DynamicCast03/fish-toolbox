if test -f ~/.bashrc
    bass source ~/.bashrc
end

function fish_toolbox_json_escape -a value
    set value (string replace -a -- "\\" "\\\\" "$value")
    set value (string replace -a -- "\"" "\\\"" "$value")
    set value (string replace -a -- (printf '\n') '\n' "$value")
    set value (string replace -a -- (printf '\r') '\r' "$value")
    set value (string replace -a -- (printf '\t') '\t' "$value")
    printf '%s' $value
end

function fish_toolbox_humanize_duration -a milliseconds
    set -l seconds (math --scale=0 "$milliseconds/1000")
    set -l hours (math --scale=0 "$seconds/3600")
    set -l minutes (math --scale=0 "($seconds%3600)/60")
    set -l remain_seconds (math --scale=0 "$seconds%60")
    set -l parts
    if test "$hours" -gt 0
        set parts $parts $hours"h"
    end
    if test "$minutes" -gt 0
        set parts $parts $minutes"m"
    end
    if test "$remain_seconds" -gt 0; or test (count $parts) -eq 0
        set parts $parts $remain_seconds"s"
    end
    string join " " $parts
end

function fish_toolbox_send_feishu_notification -a exit_status -a cmd_duration -a cwd -a command_text
    set -l duration (fish_toolbox_humanize_duration $cmd_duration)
    set -l title "Command finished"
    if test "$exit_status" -ne 0
        set title "Command failed ($exit_status)"
    end
    set title "$title: $command_text"
    set -l lines \
        "Command: $command_text" \
        "Machine: "(hostname) \
        "Finished at: "(date "+%Y-%m-%d %H:%M:%S") \
        "Directory: $cwd" \
        "Duration: $duration" \
        "Exit status: $exit_status"
    set -l escaped_lines
    for line in $lines
        set escaped_lines $escaped_lines (fish_toolbox_json_escape "$line")
    end
    set -l message (string join '\n' $escaped_lines)
    set -l payload "{\"title\":\""(fish_toolbox_json_escape "$title")"\",\"message\":\"$message\"}"
    set -l notify_url http://127.0.0.1:17991/api/feishu/notify
    if test -n "$FEISHU_WEBHOOK_URL"
        set notify_url "$FEISHU_WEBHOOK_URL"
    end
    if test -n "$FISH_TOOLBOX_NOTIFY_ENDPOINT"
        set notify_url "$FISH_TOOLBOX_NOTIFY_ENDPOINT"
    end
    command curl -fsS -X POST -H 'Content-Type: application/json' -d "$payload" "$notify_url" >/dev/null 2>&1
end

functions -e fish_prompt
functions -e fish_right_prompt
bind ` accept-autosuggestion
set -g fish_greeting ""
function fish_prompt --description 'Informative prompt'
    # Save the return status of the previous command
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.

    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color --bold $fish_color_status)
    set -l pipestatus_string (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    set -l conda_info ""
    if set -q CONDA_DEFAULT_ENV
        set conda_info (set_color yellow)"("$CONDA_DEFAULT_ENV") " (set_color normal)
    end

    printf '[%s] %s%s%s@%s %s%s %s%s%s \n> ' (date "+%H:%M:%S") "$conda_info" (set_color brblue) \
                $USER (prompt_hostname) (set_color $fish_color_cwd) (string replace -r '^'"$HOME" '~' $PWD) $pipestatus_string \
                (set_color normal)
end

if status is-interactive
    set -l fish_toolbox_dir (dirname (status --current-filename))
    command git -C "$fish_toolbox_dir" pull --ff-only </dev/null >/dev/null 2>&1 &
    disown

    function fish_toolbox_notify_started --on-event fish_preexec
        set -g fish_toolbox_last_cmd $argv[1]
    end

    function fish_toolbox_notify_ended --on-event fish_postexec
        set -l exit_status $status
        set -l cmd_duration $CMD_DURATION
        set -l threshold_ms 30000

        if set -q FISH_TOOLBOX_NOTIFY_THRESHOLD_SECONDS
            set threshold_ms (math "1000 * $FISH_TOOLBOX_NOTIFY_THRESHOLD_SECONDS")
        end

        if test -z "$cmd_duration"; or test "$cmd_duration" -lt "$threshold_ms"
            return
        end

        fish_toolbox_send_feishu_notification $exit_status $cmd_duration $PWD "$fish_toolbox_last_cmd"
    end
end
