#!/data/data/com.termux/files/usr/bin/bash

info=$(termux-wifi-connectioninfo)
rssi=$(echo "$info" | jq '.rssi')

quality=$(( (rssi + 100) * 2 ))
quality=$(( quality < 0 ? 0 : (quality > 100 ? 100 : quality) ))

if [ "$quality" -ge 75 ]; then
    icon="wifi-high-svgrepo-com.svg"
elif [ "$quality" -ge 50 ]; then
    icon="wifi-medium-svgrepo-com.svg"
elif [ "$quality" -ge 25 ]; then
    icon="wifi-low-svgrepo-com.svg"
else
    icon="wifi-off-svgrepo-com.svg"
fi

ssid=" Joy"

echo "$icon $ssid"


