#!/usr/bin/bash

#USING https://stackoverflow.com/questions/10639914/is-there-a-way-to-get-bings-photo-of-the-day "Mike McKay" answer

BG_DIR=~/.config/sway/backgrounds/bing
mkdir -p $BG_DIR
WALLPAPER_PATH=$BG_DIR/wallpaper.jpg
BACKGROUND_META=$(curl 'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US');
URL=http://bing.com$(echo $BACKGROUND_META | jq -r '.images[0].url')
curl -o $WALLPAPER_PATH $URL
