#!/bin/bash

# Toggle Default Audio Output Between Two Sinks with PipeWire

# Usage:
# 1. Modify the SINK1 and SINK2 variables with your preferred sink names.
#    To find available sink names, run 'pactl list short sinks'
# 2. Execute the script: ./toggle-sink.sh
# 3. The default audio output will switch between the specified sinks.

# Set the sink names to toggle between
SINK1="alsa_output.pci-0000_18_00.6.analog-stereo"
SINK2="alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3"

# Retrieve the current default sink name
DEFAULT=$(pactl info | grep "Default Sink:" | cut -d' ' -f 3)

# Toggle between the two sinks  
if [ "$DEFAULT" = "$SINK1" ]; then
  pactl set-default-sink "$SINK2"
else
  pactl set-default-sink "$SINK1" 
fi
