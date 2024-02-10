#!/bin/bash

amixer set Master $1
volume="$(amixer get Master | tail -1 | awk '{print $5}' | sed 's/[^0-9]*//g')"
dunstify "Progress: $volume" -h "int:value:$volume" -h string:x-dunst-stack-tag:volume
#local volume="$(amixer -c 0 get Master | tail -1 | awk '{print $4}' | sed 's/[^0-9]*//g')"
#local mute="$(amixer -c 0 get Master | tail -1 | awk '{print $6}' | sed 's/[^a-z]*//g')"
#if [[ $volume == 0 || "$mute" == "off" ]]; then
#    # Show the sound muted notification
#    dunstify -a "changeVolume" -u low -i audio-volume-muted -h string:x-dunst-stack-tag:$msgTag "Volume muted" 
#else
#    # Show the volume notification
#    dunstify -a "changeVolume" -u low -i audio-volume-high -h string:x-dunst-stack-tag:$msgTag \
#    -h int:value:"$volume" "Volume: ${volume}%"
#fi
#echo "$(eval $volume)"
