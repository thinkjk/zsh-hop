#!/usr/bin/env zsh
# zsh-hop - Jump to characters and find/replace in your command line
# Similar to vim-easymotion for your shell

# Color configuration (can be customized by users)
ZSH_HOP_LABEL_COLOR=${ZSH_HOP_LABEL_COLOR:-"\033[1;33m"}  # Bold yellow
ZSH_HOP_RESET_COLOR="\033[0m"
ZSH_HOP_PROMPT_COLOR=${ZSH_HOP_PROMPT_COLOR:-"\033[1;36m"}  # Bold cyan

# Label characters to use for hopping (in order of preference)
ZSH_HOP_LABELS=${ZSH_HOP_LABELS:-"asdfghjklqwertyuiopzxcvbnm"}

# Default keybindings
ZSH_HOP_KEY=${ZSH_HOP_KEY:-"^F"}  # Ctrl+F for hop (character or word)
ZSH_HOP_REPLACE_KEY=${ZSH_HOP_REPLACE_KEY:-"^H"}  # Ctrl+H for find/replace

# Timeout for auto-submit on single character (in seconds)
ZSH_HOP_TIMEOUT=${ZSH_HOP_TIMEOUT:-0.5}

##
# Helper function to show a temporary prompt below the command line
##
_zsh_hop_show_prompt() {
    local prompt_text="$1"
    echo -ne "\n${ZSH_HOP_PROMPT_COLOR}${prompt_text}${ZSH_HOP_RESET_COLOR}"
}

##
# Helper function to clear the temporary prompt
##
_zsh_hop_clear_prompt() {
    # Move cursor up one line and clear it
    echo -ne "\033[1A\033[2K\r"
}

##
# Main hop widget
# Shows labels for matching characters or words and jumps to selected position
##
zsh-hop-to-char() {
    # Save current buffer and cursor position
    local original_buffer="$BUFFER"
    local original_cursor=$CURSOR

    # Show prompt for search term
    echo
    echo -ne "${ZSH_HOP_PROMPT_COLOR}Hop to: ${ZSH_HOP_RESET_COLOR}"

    # Read search term from user
    local search_term=""
    local char

    # Read search string
    while true; do
        read -k 1 char

        if [[ "$char" == $'\n' ]] || [[ "$char" == $'\r' ]]; then
            # Enter pressed - search for what we have
            break
        elif [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]]; then
            # Backspace pressed
            if [[ ${#search_term} -gt 0 ]]; then
                search_term="${search_term:0:-1}"
                # Clear line and redraw prompt with updated string
                echo -ne "\r\033[K${ZSH_HOP_PROMPT_COLOR}Hop to: ${ZSH_HOP_RESET_COLOR}${search_term}"
            fi
        elif [[ "$char" == $'\e' ]]; then
            # Escape pressed - cancel
            _zsh_hop_clear_prompt
            _zsh_hop_clear_prompt
            zle redisplay
            return 0
        elif [[ "$char" == $'\t' ]]; then
            # Tab pressed - treat as Enter for single character
            if [[ ${#search_term} -eq 1 ]]; then
                break
            fi
        else
            # Normal character
            search_term+="$char"
            echo -ne "$char"

            # Auto-submit on single character followed by configurable delay
            if [[ ${#search_term} -eq 1 ]]; then
                # Give user a moment to type more
                if read -t $ZSH_HOP_TIMEOUT -k 1 next_char; then
                    # User typed another character quickly
                    if [[ "$next_char" == $'\n' ]] || [[ "$next_char" == $'\r' ]]; then
                        break
                    elif [[ "$next_char" == $'\177' ]] || [[ "$next_char" == $'\b' ]]; then
                        # Backspace
                        search_term=""
                        echo -ne "\r\033[K${ZSH_HOP_PROMPT_COLOR}Hop to: ${ZSH_HOP_RESET_COLOR}"
                    elif [[ "$next_char" == $'\e' ]]; then
                        # Escape
                        _zsh_hop_clear_prompt
                        _zsh_hop_clear_prompt
                        zle redisplay
                        return 0
                    else
                        search_term+="$next_char"
                        echo -ne "$next_char"
                    fi
                else
                    # No additional input - treat as single character search
                    break
                fi
            fi
        fi
    done

    # Clear the prompt lines
    _zsh_hop_clear_prompt
    _zsh_hop_clear_prompt

    # Handle empty search
    if [[ -z "$search_term" ]]; then
        zle redisplay
        return 0
    fi

    # Find all positions based on search term length
    local -a positions
    local -a labels
    local label_idx=0

    if [[ ${#search_term} -eq 1 ]]; then
        # Single character search - find all occurrences of the character
        local pos=0
        while [[ $pos -lt ${#BUFFER} ]]; do
            if [[ "${BUFFER:$pos:1}" == "$search_term" ]]; then
                positions+=($pos)
                # Assign label from our label string
                if [[ $label_idx -lt ${#ZSH_HOP_LABELS} ]]; then
                    labels+=(${ZSH_HOP_LABELS:$label_idx:1})
                    ((label_idx++))
                fi
            fi
            ((pos++))
        done
    else
        # Multi-character search - find all occurrences of the word/substring
        local pos=0
        local search_len=${#search_term}
        while [[ $pos -le $((${#BUFFER} - search_len)) ]]; do
            if [[ "${BUFFER:$pos:$search_len}" == "$search_term" ]]; then
                positions+=($pos)
                # Assign label from our label string
                if [[ $label_idx -lt ${#ZSH_HOP_LABELS} ]]; then
                    labels+=(${ZSH_HOP_LABELS:$label_idx:1})
                    ((label_idx++))
                fi
            fi
            ((pos++))
        done
    fi

    # If no matches found
    if [[ ${#positions[@]} -eq 0 ]]; then
        zle redisplay
        return 0
    fi

    # If only one match, jump directly to it
    if [[ ${#positions[@]} -eq 1 ]]; then
        CURSOR=${positions[1]}
        zle redisplay
        return 0
    fi

    # Multiple matches - show labels and let user choose
    # Build the labels line - create labels aligned with match positions
    local display_line=""
    local current_pos=0
    local match_idx=1

    for pos in "${positions[@]}"; do
        # Add spaces until we reach the position
        while [[ $current_pos -lt $pos ]]; do
            display_line+=" "
            ((current_pos++))
        done
        # Add the label
        display_line+="${labels[$match_idx]}"
        ((current_pos++))
        ((match_idx++))
    done

    # Print the command text and labels below the current command line
    echo
    echo "${BUFFER}"
    echo "${ZSH_HOP_LABEL_COLOR}${display_line}${ZSH_HOP_RESET_COLOR}"
    echo -ne "${ZSH_HOP_PROMPT_COLOR}Select label: ${ZSH_HOP_RESET_COLOR}"

    # Read label selection
    local selected_label
    read -k 1 selected_label

    # Clear our display (4 lines: blank, command copy, labels, prompt)
    _zsh_hop_clear_prompt  # Clear prompt line
    _zsh_hop_clear_prompt  # Clear label line
    _zsh_hop_clear_prompt  # Clear command copy
    _zsh_hop_clear_prompt  # Clear blank line

    # Find the position corresponding to the selected label
    local target_pos=-1
    match_idx=1
    for pos in "${positions[@]}"; do
        if [[ "${labels[$match_idx]}" == "$selected_label" ]]; then
            target_pos=$pos
            break
        fi
        ((match_idx++))
    done

    # Jump to the selected position
    if [[ $target_pos -ge 0 ]]; then
        CURSOR=$target_pos
    fi

    zle redisplay
}

##
# Find and replace widget
# Prompts for find and replace strings and performs replacement on current line
##
zsh-hop-find-replace() {
    # Save current buffer
    local original_buffer="$BUFFER"
    local original_cursor=$CURSOR

    # Prompt for find string
    echo
    echo -ne "${ZSH_HOP_PROMPT_COLOR}Find: ${ZSH_HOP_RESET_COLOR}"

    local find_str=""
    local char

    # Read find string
    while true; do
        read -k 1 char

        if [[ "$char" == $'\n' ]] || [[ "$char" == $'\r' ]]; then
            # Enter pressed
            break
        elif [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]]; then
            # Backspace pressed
            if [[ ${#find_str} -gt 0 ]]; then
                find_str="${find_str:0:-1}"
                # Clear line and redraw prompt with updated string
                echo -ne "\r\033[K${ZSH_HOP_PROMPT_COLOR}Find: ${ZSH_HOP_RESET_COLOR}${find_str}"
            fi
        elif [[ "$char" == $'\e' ]]; then
            # Escape pressed - cancel
            _zsh_hop_clear_prompt
            _zsh_hop_clear_prompt
            zle redisplay
            return 0
        else
            # Normal character
            find_str+="$char"
            echo -ne "$char"
        fi
    done

    # If empty find string, cancel
    if [[ -z "$find_str" ]]; then
        _zsh_hop_clear_prompt
        _zsh_hop_clear_prompt
        zle redisplay
        return 0
    fi

    # Check if find string exists in buffer
    if [[ "$BUFFER" != *"$find_str"* ]]; then
        echo
        echo -ne "${ZSH_HOP_PROMPT_COLOR}Not found: ${find_str}${ZSH_HOP_RESET_COLOR}"
        sleep 1
        _zsh_hop_clear_prompt
        _zsh_hop_clear_prompt
        _zsh_hop_clear_prompt
        zle redisplay
        return 0
    fi

    # Prompt for replace string
    echo
    echo -ne "${ZSH_HOP_PROMPT_COLOR}Replace with: ${ZSH_HOP_RESET_COLOR}"

    local replace_str=""

    # Read replace string
    while true; do
        read -k 1 char

        if [[ "$char" == $'\n' ]] || [[ "$char" == $'\r' ]]; then
            # Enter pressed
            break
        elif [[ "$char" == $'\177' ]] || [[ "$char" == $'\b' ]]; then
            # Backspace pressed
            if [[ ${#replace_str} -gt 0 ]]; then
                replace_str="${replace_str:0:-1}"
                # Clear line and redraw prompt with updated string
                echo -ne "\r\033[K${ZSH_HOP_PROMPT_COLOR}Replace with: ${ZSH_HOP_RESET_COLOR}${replace_str}"
            fi
        elif [[ "$char" == $'\e' ]]; then
            # Escape pressed - cancel
            _zsh_hop_clear_prompt
            _zsh_hop_clear_prompt
            _zsh_hop_clear_prompt
            zle redisplay
            return 0
        else
            # Normal character
            replace_str+="$char"
            echo -ne "$char"
        fi
    done

    # Clear the prompt lines (3 lines: blank, find, replace)
    _zsh_hop_clear_prompt
    _zsh_hop_clear_prompt
    _zsh_hop_clear_prompt

    # Perform the replacement (replaces all occurrences)
    BUFFER="${BUFFER//$find_str/$replace_str}"

    # Try to maintain cursor position relative to text
    # If cursor was after the replaced text, adjust it
    local len_diff=$((${#replace_str} - ${#find_str}))
    if [[ $len_diff -ne 0 ]]; then
        # Count how many replacements occurred before cursor
        local before_cursor="${original_buffer:0:$original_cursor}"
        local replacements_before=0
        local temp_str="$before_cursor"
        while [[ "$temp_str" == *"$find_str"* ]]; do
            temp_str="${temp_str/$find_str/}"
            ((replacements_before++))
        done

        # Adjust cursor position
        CURSOR=$((original_cursor + (len_diff * replacements_before)))

        # Ensure cursor is within bounds
        if [[ $CURSOR -gt ${#BUFFER} ]]; then
            CURSOR=${#BUFFER}
        elif [[ $CURSOR -lt 0 ]]; then
            CURSOR=0
        fi
    fi

    zle redisplay
}

# Register the widgets with ZLE
zle -N zsh-hop-to-char
zle -N zsh-hop-find-replace

# Bind to default keys (users can override by setting variables before loading)
bindkey "$ZSH_HOP_KEY" zsh-hop-to-char
bindkey "$ZSH_HOP_REPLACE_KEY" zsh-hop-find-replace
