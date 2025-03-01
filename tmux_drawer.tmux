#!/usr/bin/env bash

# Get the current directory where the script is located
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default drawer width (second argument can override)
DRAWER_WIDTH="20"
[[ -n "$2" ]] && DRAWER_WIDTH="$2"

# Ensure we are inside a tmux session
if [ -z "$TMUX" ]; then
    echo "Error: This script must be run inside a tmux session."
    exit 1
fi

# ---------------------------
# State management functions
# ---------------------------

get_window_drawer_state() {
    local window_id="$1"
    local session_id
    session_id=$(tmux display-message -p "#{session_id}")
    local state_var="DRAWER_STATE_${session_id}_${window_id}"
    tmux show-environment -g "$state_var" 2>/dev/null | cut -d= -f2
}

set_window_drawer_state() {
    local window_id="$1"
    local pane_id="$2"
    local visible="$3"
    local session_id
    session_id=$(tmux display-message -p "#{session_id}")
    local state_var="DRAWER_STATE_${session_id}_${window_id}"
    tmux set-environment -g "$state_var" "${pane_id}:${visible}"
}

clear_window_drawer_state() {
    local window_id="$1"
    local session_id
    session_id=$(tmux display-message -p "#{session_id}")
    local state_var="DRAWER_STATE_${session_id}_${window_id}"
    tmux set-environment -g -u "$state_var"
}

get_drawer_pane_from_state() {
    local state="$1"
    echo "${state%%:*}"
}

is_drawer_visible_from_state() {
    local state="$1"
    local visible="${state#*:}"
    [[ "$visible" == "1" ]]
}

# -------------------------------
# Drawer existence and retrieval
# -------------------------------

drawer_exists() {
    local window_id
    window_id=$(tmux display-message -p "#{window_id}")
    local hidden_window_name="drawer_${window_id}"
    local state
    state=$(get_window_drawer_state "$window_id")
    
    if [[ -n "$state" ]]; then
        local drawer_pane
        drawer_pane=$(get_drawer_pane_from_state "$state")
        if is_drawer_visible_from_state "$state"; then
            tmux list-panes -t "$window_id" -F "#{pane_id}" | grep -q "^${drawer_pane}$" && return 0
        else
            tmux list-windows -F "#{window_name}" | grep -q "^${hidden_window_name}$" &&
            tmux list-panes -t "${hidden_window_name}" -F "#{pane_id}" | grep -q "^${drawer_pane}$" && return 0
        fi
    fi
    return 1
}

get_drawer_pane_id() {
    local window_id
    window_id=$(tmux display-message -p "#{window_id}")
    local hidden_window_name="drawer_${window_id}"
    local pane_id state
    state=$(get_window_drawer_state "$window_id")
    
    if [[ -n "$state" ]]; then
        pane_id=$(get_drawer_pane_from_state "$state")
    fi

    # If state is empty but a hidden window exists, get its first pane and update the state.
    if [[ -z "$pane_id" ]] && tmux list-windows -F "#{window_name}" | grep -q "^${hidden_window_name}$"; then
        pane_id=$(tmux list-panes -t "${hidden_window_name}" -F "#{pane_id}" | head -n1)
        set_window_drawer_state "$window_id" "$pane_id" "0"
    fi
    
    echo "$pane_id"
}

# --------------------------
# Drawer toggle functionality
# --------------------------

toggle_drawer() {
    local current_pane window_id session_id hidden_window_name drawer_pane state
    current_pane=$(tmux display-message -p "#{pane_id}")
    window_id=$(tmux display-message -p "#{window_id}")
    session_id=$(tmux display-message -p "#{session_id}")
    hidden_window_name="drawer_${window_id}"

    if drawer_exists; then
        drawer_pane=$(get_drawer_pane_id)
        state=$(get_window_drawer_state "$window_id")
        
        if is_drawer_visible_from_state "$state" &&
           tmux list-panes -t "$window_id" -F "#{pane_id}" | grep -q "^${drawer_pane}$"; then
            # Hide drawer: break pane to a new hidden window and update state.
            tmux break-pane -dP -F "#{window_id}" -n "$hidden_window_name" -s "${drawer_pane}" >/dev/null
            set_window_drawer_state "$window_id" "$drawer_pane" "0"
            hide_drawer_window "$hidden_window_name"
            tmux select-pane -t "$current_pane"
        else
            if tmux list-windows -F "#{window_name}" | grep -q "^${hidden_window_name}$"; then
                # Retrieve pane from hidden window, join it back, and update state.
                local hidden_pane
                hidden_pane=$(tmux list-panes -t "${hidden_window_name}" -F "#{pane_id}" | head -n1)
                tmux join-pane -h -l "${DRAWER_WIDTH}%" -s "${session_id}:${hidden_window_name}.0" -t "${window_id}"
                drawer_pane=$(tmux display-message -p "#{pane_id}")
                set_window_drawer_state "$window_id" "$drawer_pane" "1"
                tmux select-pane -t "$drawer_pane"
            else
                # Create new drawer if no hidden window exists.
                tmux split-window -h -l "${DRAWER_WIDTH}%" -c "#{pane_current_path}"
                drawer_pane=$(tmux display-message -p "#{pane_id}")
                set_window_drawer_state "$window_id" "$drawer_pane" "1"
                tmux select-pane -t "$drawer_pane"
            fi
        fi
    else
        # No existing drawer: create one.
        tmux split-window -h -l "${DRAWER_WIDTH}%" -c "#{pane_current_path}"
        drawer_pane=$(tmux display-message -p "#{pane_id}")
        set_window_drawer_state "$window_id" "$drawer_pane" "1"
        tmux select-pane -t "$drawer_pane"
    fi
}

# ----------------------------
# Helper to hide the drawer window
# ----------------------------

hide_drawer_window() {
    local window_name="$1"
    tmux set-window-option -t "$window_name" monitor-silence 0
    tmux set-window-option -t "$window_name" monitor-activity off
    tmux set-window-option -t "$window_name" monitor-bell off
    tmux set-window-option -t "$window_name" pane-border-status off
    tmux set-window-option -t "$window_name" visual-activity off
    tmux set-window-option -t "$window_name" visual-bell off
    tmux set-window-option -t "$window_name" visual-silence off
    tmux set-window-option -t "$window_name" window-status-format ""
    tmux set-window-option -t "$window_name" window-status-current-format ""
    tmux set-window-option -t "$window_name" hidden on
}

# -------------------------
# Initialization routine
# -------------------------

init() {
    # Hide any existing drawer windows.
    for window in $(tmux list-windows -F "#{window_name}" | grep "^drawer_"); do
        hide_drawer_window "$window"
    done
}

# -------------------------
# Main Execution
# -------------------------

main() {
    toggle_drawer
}

# Execute initialization and main if not running in "bind" mode.
if [[ "$1" != "bind" ]]; then
    init
    main
fi
