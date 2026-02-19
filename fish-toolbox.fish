functions -e fish_prompt
functions -e fish_right_prompt
bind ` accept-autosuggestion
set -g fish_greeting ""
function fish_prompt --description 'Informative prompt'
    # Save the return status of the previous command
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.

    if functions -q fish_is_root_user; and fish_is_root_user
        printf '%s@%s %s%s%s# ' $USER (prompt_hostname) (set -q fish_color_cwd_root
                                                                 and set_color $fish_color_cwd_root
                                                                 or set_color $fish_color_cwd) \
                    (prompt_pwd) (set_color normal)
    else
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
end