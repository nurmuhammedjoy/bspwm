#!/data/data/com.termux/files/usr/bin/bash

vol=$(termux-volume | grep '"music"' -A2 | grep '"volume"' | awk -F ': ' '{print $2}' | tr -d ', ')

[ -z "$vol" ] && vol=0

if [ "$vol" -eq 0 ]; then
    icon="volume-slash-svgrepo-com.svg"
elif [ "$vol" -le 30 ]; then
    icon="volume-low-svgrepo-com.svg"
else
    icon="volume-high-svgrepo-com.svg"
fi

echo "$icon $vol%"


