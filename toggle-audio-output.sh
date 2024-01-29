#!/bin/bash 

# Toggle Between Two Audio Sinks
#
# This script allows toggling the default audio output sink between two 
# pre-selected sinks configured by the user. It stores the selected sink  
# names in a config file and toggles between them each time the script is
# executed.
#
# The user must first run the script with the --reconfigure argument to 
# choose the two sink names to toggle between. This will prompt for sink
# selections and store them in the config file.
#
# On subsequent runs, the script will simply switch the default audio sink
# between the two configured ones. If the config is deleted, --reconfigure
# must be used again to choose new sinks.

# Usage:
# toggle-sinks.sh [-h|--help] [--reconfigure]
#
# Arguments:
#   -h, --help      Prints help information
#   --reconfigure   Interactive mode to choose two sink names to toggle between
#                   
# If no arguments provided, simply toggles between the configured sinks.

# Config file path
CONFIG_FILE=~/.config/toggle-sinks.conf


if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Toggle between two selected audio sinks"
    echo
    echo "Usage: $0 [-h|--help] [--reconfigure]"
    echo
    echo "Arguments:"
    echo "  -h, --help         Show this help message" 
    echo "  --reconfigure      Interactive mode to choose sinks"
    echo
    echo "Run with no arguments to toggle between configured sinks."
    echo "Use --reconfigure on first run or to choose new sinks."
    
    exit 0
fi

if [ "$1" = "--reconfigure" ]; then
    
    # List available sinks
    echo "Available sinks:"
    pactl list short sinks | cat -n
    
    # Prompt user to select by number
    read -p "Select first sink number: " SNK1
    read -p "Select second sink number: " SNK2
    
    # Get sink names from numbers
    SINK1=$(pactl list short sinks | sed -n "$SNK1"p | cut -f2)
    SINK2=$(pactl list short sinks | sed -n "$SNK2"p | cut -f2)
    
    # Save selections
    echo "SINK1=$SINK1" > $CONFIG_FILE
    echo "SINK2=$SINK2" >> $CONFIG_FILE
    
fi

# Check if config file exists and has values
if [ ! -f "$CONFIG_FILE" ] || [ ! -s "$CONFIG_FILE" ]; then
    echo "No sink selections found. Please run with --reconfigure"
    exit 1
fi

# Config exists, load sinks  
source $CONFIG_FILE


# Check if sinks exist
if ! pactl list short sinks | grep -q "$SINK1"; then
    echo "Sink $SINK1 not found. Please run with --reconfigure" 
    exit 1
fi

if ! pactl list short sinks | grep -q "$SINK2"; then
    echo "Sink $SINK2 not found. Please run with --reconfigure"
    exit 1  
fi

# Get the current default sink name
DEFAULT=$(pactl info | grep "Default Sink:" | cut -d' ' -f 3)

# Toggle between the two sinks
if [ "$DEFAULT" = "$SINK1" ]; then
    pactl set-default-sink "$SINK2"
else
    pactl set-default-sink "$SINK1"
fi
