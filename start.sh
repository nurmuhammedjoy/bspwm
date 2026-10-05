#!/data/data/com.termux/files/usr/bin/bash

# Kill previous X11 processes
pkill -f "termux.x11" 2>/dev/null

# Termux runtime directory
export XDG_RUNTIME_DIR="${TMPDIR}"

# X display
export DISPLAY=:0

# Audio
pulseaudio --start \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --exit-idle-time=-1

# Start Termux:X11
termux-x11 :0 >/dev/null 2>&1 &

# Wait for X server
sleep 5

# Launch Termux:X11 Android activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

sleep 3

# Audio
export PULSE_SERVER=127.0.0.1

# Use Termux's home directory for the log
LOGFILE="$HOME/i3.log"

# Start i3
dbus-launch --exit-with-session bspwm
>"$LOGFILE" 2>&1 &

echo "i3 started. Log: $LOGFILE"
