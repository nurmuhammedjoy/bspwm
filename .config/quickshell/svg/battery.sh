#!/data/data/com.termux/files/usr/bin/bash

capacity=$(termux-battery-status | grep 'percentage' | awk -F ': ' '{print $2}' | tr -d ', ')
charging=$(termux-battery-status | grep 'charging' | awk -F ': ' '{print $2}' | tr -d ', ')

if [ "$charging" = "true" ]; then
    icon="battery-bolt-alt-svgrepo-com.svg"
else
    if   [ "$capacity" -ge 90 ]; then icon="battery-full-svgrepo-com.svg"  
    elif [ "$capacity" -ge 50 ]; then icon="battery-mid-svgrepo-com.svg"  
    elif [ "$capacity" -ge 25 ]; then icon="battery-low-svgrepo-com.svg"  
    else icon="battery-empty-svgrepo-com.svg"
    fi
fi

echo "$icon $capacity%"


