#!/bin/bash

# User interface components for Omni-Installer

# Progress bar function
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local width=50
    
    local progress=$((current * width / total))
    local percentage=$((current * 100 / total))
    
    printf "\r${message}: ["
    for ((i=0; i<width; i++)); do
        if [[ $i -lt $progress ]]; then
            printf "="
        else
            printf " "
        fi
    done
    printf "] %d%%" $percentage
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Spinner function
show_spinner() {
    local pid="$1"
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(((i+1) % ${#spin}))
        printf "\r${BLUE}%s${NC} %s" "${spin:$i:1}" "$message"
        sleep 0.1
    done
    
    printf "\r"
}

# Menu selection with arrow keys
select_menu_item() {
    local items=("$@")
    local selected=0
    local key
    
    # Hide cursor
    tput civis
    
    while true; do
        # Clear and redraw menu
        for i in "${!items[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "${GREEN}▶ ${items[$i]}${NC}"
            else
                echo "  ${items[$i]}"
            fi
        done
        
        # Read key
        read -rsn1 key
        case "$key" in
            $'\x1b') # Escape sequence
                read -rsn2 key
                case "$key" in
                    '[A') # Up arrow
                        ((selected--))
                        if [[ $selected -lt 0 ]]; then
                            selected=$((${#items[@]} - 1))
                        fi
                        ;;
                    '[B') # Down arrow
                        ((selected++))
                        if [[ $selected -ge ${#items[@]} ]]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            '') # Enter key
                break
                ;;
        esac
        
        # Move cursor up to redraw
        tput cuu ${#items[@]}
    done
    
    # Show cursor
    tput cnorm
    
    echo "$selected"
}

# Display box with text
display_box() {
    local title="$1"
    local content="$2"
    local width="${3:-60}"
    
    # Top border
    printf "┌"
    for ((i=0; i<width-2; i++)); do printf "─"; done
    printf "┐\n"
    
    # Title
    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local padding=$(( (width - title_len - 2) / 2 ))
        printf "│"
        for ((i=0; i<padding; i++)); do printf " "; done
        printf "%s" "$title"
        for ((i=0; i<width-title_len-padding-2; i++)); do printf " "; done
        printf "│\n"
        
        # Separator
        printf "├"
        for ((i=0; i<width-2; i++)); do printf "─"; done
        printf "┤\n"
    fi
    
    # Content
    echo "$content" | while IFS= read -r line; do
        local line_len=${#line}
        printf "│ %s" "$line"
        for ((i=0; i<width-line_len-3; i++)); do printf " "; done
        printf "│\n"
    done
    
    # Bottom border
    printf "└"
    for ((i=0; i<width-2; i++)); do printf "─"; done
    printf "┘\n"
}

# Input validation
validate_input() {
    local input="$1"
    local pattern="$2"
    local error_msg="$3"
    
    if [[ ! "$input" =~ $pattern ]]; then
        print_error "$error_msg"
        return 1
    fi
    
    return 0
}

# Multi-select menu
multi_select_menu() {
    local items=("$@")
    local selected=()
    local current=0
    local key
    
    # Initialize selection array
    for ((i=0; i<${#items[@]}; i++)); do
        selected[i]=false
    done
    
    tput civis
    
    while true; do
        clear
        print_header "Select multiple items (Space to toggle, Enter to confirm):"
        echo ""
        
        for i in "${!items[@]}"; do
            local marker=" "
            if [[ "${selected[$i]}" == "true" ]]; then
                marker="✓"
            fi
            
            if [[ $i -eq $current ]]; then
                echo -e "${GREEN}▶ [$marker] ${items[$i]}${NC}"
            else
                echo "  [$marker] ${items[$i]}"
            fi
        done
        
        read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 key
                case "$key" in
                    '[A') # Up arrow
                        ((current--))
                        if [[ $current -lt 0 ]]; then
                            current=$((${#items[@]} - 1))
                        fi
                        ;;
                    '[B') # Down arrow
                        ((current++))
                        if [[ $current -ge ${#items[@]} ]]; then
                            current=0
                        fi
                        ;;
                esac
                ;;
            ' ') # Space - toggle selection
                if [[ "${selected[$current]}" == "true" ]]; then
                    selected[$current]=false
                else
                    selected[$current]=true
                fi
                ;;
            '') # Enter - confirm selection
                break
                ;;
        esac
    done
    
    tput cnorm
    
    # Return selected indices
    local result=()
    for i in "${!selected[@]}"; do
        if [[ "${selected[$i]}" == "true" ]]; then
            result+=("$i")
        fi
    done
    
    echo "${result[@]}"
}
