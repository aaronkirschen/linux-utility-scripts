#!/bin/bash

# Configure multiple monitors on Linux KDE kwin_wayland
#
# This script uses kscreen-doctor to manage multiple monitors:
# - List monitors
# - Enable only left or right monitor 
# - Disable specified monitors
#
# It saves monitor positions and priorities to ~/.config/monitor_config.
#
# Usage:
#   monitor-config [OPTIONS] [MONITORS_TO_DISABLE]
#
# Options:
#   -l, --list               List monitors and exit
#   -L, --left               Enable only leftmost monitor
#   -R, --right              Enable only rightmost monitor 
#
# Arguments:
#   MONITORS_TO_DISABLE      Space separated list of monitors to disable
#
# Example:
#   monitor-config -L         # Enable only leftmost monitor
#   monitor-config -R         # Enable only rightmost monitor
#   monitor-config HDMI-1 DP-1 # Disable HDMI-1 and DP-1 monitors

CONFIG_FILE=~/.config/monitor_config

POSITIONAL_ARGS=()

LIST=false
LEFT_ONLY=false
RIGHT_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
    -l | --list)
        LIST=true
        shift # past argument
        ;;
    -L | --left)
        LEFT_ONLY=true
        shift
        ;;
    -R | --right)
        RIGHT_ONLY=true
        shift
        ;;
    *)

        POSITIONAL_ARGS+=("$1") # save positional arg
        shift                   # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# List monitors
if $LIST; then
    echo "Monitors:"
    kscreen-doctor -o | grep 'Output: ' | awk '{print $3}'
    exit
fi

# Get monitor info
INFO=$(kscreen-doctor -o)

# Get disable list from argument
DISABLE_MONITORS="$1"

# Populate config map
declare -A POSITIONS PRIORITIES
while IFS= read -r LINE; do
    MONITOR_NAME=$(echo "$LINE" | awk -F' ' '{print $3}')
    POSITION=$(echo "$LINE" | awk -F' ' '{for (i=1; i<=NF; i++) if ($i ~ /Geometry:/) print $(i+1)}')
    POSITIONS[$MONITOR_NAME]=$POSITION
    PRIORITY=$(echo "$LINE" | awk -F' ' '{for (i=1; i<=NF; i++) if ($i ~ /priority/) print $(i+1)}')
    PRIORITIES[$MONITOR_NAME]=$PRIORITY
done < <(echo "$INFO" | grep 'Output:')

# Get left/right monitors
if $LEFT_ONLY; then
    LEFT_MONITOR=$(for m in "${!POSITIONS[@]}"; do
        LEFT_X=$(echo ${POSITIONS[$m]} | awk -F',' '{print $1}')
        echo $LEFT_X $m
    done | sort -n | head -n1 | awk '{print $2}')
    echo "Enabling only $LEFT_MONITOR"

elif $RIGHT_ONLY; then
    RIGHT_MONITOR=$(for m in "${!POSITIONS[@]}"; do
        RIGHT_X=$(echo ${POSITIONS[$m]} | awk -F',' '{print $1}')
        echo $RIGHT_X $m
    done | sort -nr | head -n1 | awk '{print $2}')

    echo "Enabling only $RIGHT_MONITOR"
fi

# Build command
CMD="kscreen-doctor"

for MONITOR in $(echo "$INFO" | grep 'Output: ' | awk '{print $3}'); do

    if $LEFT_ONLY; then
        if [ "$MONITOR" != "$LEFT_MONITOR" ]; then
            # Disable all monitors except left one
            CMD="$CMD output.$MONITOR.disable"
        fi
    elif $RIGHT_ONLY; then
        if [ "$MONITOR" != "$RIGHT_MONITOR" ]; then
            # Disable all monitors except right one
            CMD="$CMD output.$MONITOR.disable"
        fi
    else

        if [[ " $DISABLE_MONITORS " =~ " $MONITOR " ]]; then
            POS=${POSITIONS[$MONITOR]}
            if grep -q "$MONITOR" $CONFIG_FILE; then
                sed -i "/^$MONITOR/c$MONITOR $POS ${PRIORITIES[$MONITOR]}" $CONFIG_FILE || echo "Failed to save $MONITOR position" >&2
            else
                echo "$MONITOR $POS ${PRIORITIES[$MONITOR]}" >>$CONFIG_FILE
            fi
            CMD="$CMD output.$MONITOR.disable"
        else

            POS=$(grep "$MONITOR" $CONFIG_FILE | awk '{print $2}')
            PRIORITY=$(grep "$MONITOR" $CONFIG_FILE | awk '{print $3}')

            if [ -z "$POS" ]; then
                POS=${POSITIONS[$MONITOR]}
                PRIORITY=${PRIORITIES[$MONITOR]}
            fi
            CMD="$CMD output.$MONITOR.enable output.$MONITOR.position.$POS output.$MONITOR.priority.$PRIORITY"

        fi
    fi
done

# Execute command
CMD="$(echo "$CMD" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')" # Clean command
$CMD
