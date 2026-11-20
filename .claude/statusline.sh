#!/bin/bash

# Read the full JSON payload from stdin
input=$(cat)

# Extract basic attributes
# Works under Claude Code and Copilot CLI: Copilot sends no rate_limits but a premium request count,
# and its own context % field. The anchor is the launch dir, which picks the AGENTS.md/CLAUDE.md chain.
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
CTX=$(echo "$input" | jq -r '.context_window.current_context_used_percentage // .context_window.used_percentage // 0' | cut -d. -f1)
ANCHOR=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // empty')
ANCHOR=${ANCHOR/#$HOME/\~}
PREMIUM=$(echo "$input" | jq -r '.cost.total_premium_requests // empty')

# Extract 5h & 7d limits
H5_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
H5_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

D7_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
D7_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ANSI Escape Colors
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Helper function to get color based on threshold percentage
get_color() {
    local pct=$1
    if [ -z "$pct" ] || [ "$pct" = "null" ]; then
        echo -n "$RESET"
    elif [ "$pct" -ge 80 ]; then
        echo -n "$RED"
    elif [ "$pct" -ge 50 ]; then
        echo -n "$YELLOW"
    else
        echo -n "$GREEN"
    fi
}

# Helper function to format countdown timer if near the limit (>75%)
get_reset_time() {
    local pct=$1
    local reset_epoch=$2
    
    if [ -n "$pct" ] && [ "$pct" != "null" ] && [ "$pct" -ge 75 ] && [ -n "$reset_epoch" ] && [ "$reset_epoch" != "null" ]; then
        local current_epoch=$(date +%s)
        local diff=$((reset_epoch - current_epoch))
        
        if [ $diff -gt 0 ]; then
            local mins=$(( (diff / 60) % 60 ))
            local hours=$(( diff / 3600 ))
            if [ $hours -gt 0 ]; then
                echo -n " (resets in ${hours}h ${mins}m)"
            else
                echo -n " (resets in ${mins}m)"
            fi
        fi
    fi
}

# 1. Fetch Git Branch Name (if inside a git repo)
GIT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$GIT_BRANCH" ]; then
    BRANCH_INFO="${CYAN} $GIT_BRANCH${RESET} | "
else
    BRANCH_INFO=""
fi

# 2. Color-code context window
CTX_COLOR=$(get_color "$CTX")
OUTPUT="${ANCHOR:+$ANCHOR | }${BRANCH_INFO}${MODEL} | ctx ${CTX_COLOR}${CTX}%${RESET}"

# 3. Copilot: premium requests replace the 5h/7d limits
if [ -n "$PREMIUM" ]; then
    echo -e "$OUTPUT | premium $PREMIUM"
    exit 0
fi

# 4. Add 5-hour limit if available
if [ -n "$H5_PCT" ] && [ "$H5_PCT" != "null" ]; then
    H5_COLOR=$(get_color "$H5_PCT")
    H5_TIME=$(get_reset_time "$H5_PCT" "$H5_RESET")
    OUTPUT="$OUTPUT | 5h ${H5_COLOR}${H5_PCT}%${RESET}${H5_TIME}"
else
    OUTPUT="$OUTPUT | 5h -%"
fi

# 5. Add 7-day limit if available
if [ -n "$D7_PCT" ] && [ "$D7_PCT" != "null" ]; then
    D7_COLOR=$(get_color "$D7_PCT")
    D7_TIME=$(get_reset_time "$D7_PCT" "$D7_RESET")
    OUTPUT="$OUTPUT | 7d ${D7_COLOR}${D7_PCT}%${RESET}${D7_TIME}"
else
    OUTPUT="$OUTPUT | 7d -%"
fi

# Render the final status line
echo -e "$OUTPUT"
