#!/usr/bin/env bash

# City can contain spaces. --short prints icon and temperature only.
if [[ "$#" -gt 0 && "$*" != *"--short"* ]]; then
  CITY="$*"
else
  CITY="Dhaka"
fi

SHORT=false
[[ "$*" == *"--short"* ]] && SHORT=true

RAW=$(curl -s "wttr.in/${CITY}?format=%C|%t" || echo "N/A|N/A")

COND=$(echo "$RAW" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]' | xargs)
TEMP=$(echo "$RAW" | cut -d'|' -f2 | sed 's/+//' | xargs)

ICON="weather-symbol-10-svgrepo-com.svg"

case "$COND" in
*clear* | *sunny*) ICON="weather-2-svgrepo-com.svg" ;;
*partly* | *few* | *overcast*) ICON="weather-symbol-7-svgrepo-com.svg" ;;
*cloud* | *clouds*) ICON="weather-symbol-10-svgrepo-com.svg" ;;
*rain* | *drizzle* | *shower*) ICON="weather-showers-svgrepo-com.svg" ;;
*thunder* | *storm*) ICON="thunder-svgrepo-com.svg" ;;
*mist* | *fog* | *haze*) ICON="fog-svgrepo-com.svg" ;;
*) ICON="weather-symbol-10-svgrepo-com.svg" ;;
esac

# Offline fallbacks.
[[ "$TEMP" == "N/A" ]] && TEMP="--°C"
[[ "$RAW" == "N/A|N/A" ]] && CITY="Unknown"

if $SHORT; then
  printf '%s %s\n' "$ICON" "$TEMP"
else
  printf '%s %s %s\n' "$ICON" " $CITY" "$TEMP"
fi

