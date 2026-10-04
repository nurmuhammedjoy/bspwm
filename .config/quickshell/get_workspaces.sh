#!/usr/bin/env bash
set -uo pipefail

# Workspace feed for the bar. Subscribes to bspwm events and rewrites
# workspaces.json on change; shell.qml watches the file, so an idle bar
# has no poll timer and costs nothing.
#
# A state file is used because quickshell 0.3.1 only hands a Process'
# stdout to QML once the process exits, so a subscriber cannot stream.
# bspc subscribe -f would deadlock bspwm 0.9.12 opening its fifo.

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$PREFIX/tmp}"

STATE=${BSPWM_WS_STATE:-"$(dirname -- "$0")/workspaces.json"}
# Minimum seconds between writes. The first event of a burst publishes
# immediately so the bar feels instant; events arriving during a snapshot
# fold into the next write, so a burst costs one render, not many.
THROTTLE=${BSPWM_WS_THROTTLE:-0.08}
# How long to block on the event stream before checking we are still wanted.
IDLE=${BSPWM_WS_IDLE:-5}

# 0.9.12 only emits all, report, monitor, desktop and node events; window
# opens, closes and focus changes all arrive as node events.
EVENTS=(desktop monitor node)

work=$(mktemp -d) || exit 1
fifo="$XDG_RUNTIME_DIR/quickshell-workspaces.$$"

subscriber=
cleanup() {
    [[ -n $subscriber ]] && kill "$subscriber" 2>/dev/null
    rm -rf "$work" "$fifo"
}
trap cleanup EXIT INT TERM

# Writes the current state as one JSON array on stdout.
snapshot() {
    # The focused monitor tree carries its focusedDesktopId, so one call
    # covers the common single-monitor case; the monitor list only runs to
    # find out whether other trees must be added, and in parallel.
    bspc query --tree --monitor > "$work/tree" &
    local tree_pid=$!
    bspc query --monitors --names > "$work/mons" &
    local mons_pid=$!
    wait "$tree_pid" "$mons_pid"

    if [[ ! -s $work/tree ]]; then
        echo "[]"
        return 0
    fi

    # Desktops of the other monitors, multi-monitor setups only.
    : > "$work/rest"
    while IFS= read -r monitor; do
        [[ -n $monitor ]] || continue
        grep -qF "\"name\":\"$monitor\"" "$work/tree" && continue
        bspc query --tree --monitor "$monitor" >> "$work/rest" 2>/dev/null
    done < "$work/mons"

    # The focused monitor tree is first, so jq can read focus from its
    # focusedDesktopId without a third bspc call.
    cat "$work/tree" "$work/rest" | jq -cs '
        .[0] as $focus
        | [ .[]
          | .name as $monitor
          | .desktops
          | to_entries[]
          | .key as $slot
          | .value as $desktop
          | [ $desktop | .. | objects | select(.client != null) ] as $windows
          | {
              # Numeric desktop names keep their number; named desktops
              # fall back to their slot so pills stay 1..n ordered.
              num: (($desktop.name | tonumber?) // ($slot + 1)),
              id: $desktop.id,
              name: $desktop.name,
              monitor: $monitor,
              visible: (($windows | length) > 0),
              focused: (($monitor == $focus.name) and ($desktop.id == $focus.focusedDesktopId)),
              urgent: ($windows | map(.client.urgent // false) | any)
            } ]'
}

# Rewrite only when something changed, every write re-renders the bar.
last=""
publish() {
    local out
    out=$(snapshot)
    [[ -n $out ]] || return 0
    [[ $out == "$last" ]] && return 0
    printf '%s\n' "$out" > "$STATE"
    last=$out
}

# Event stream over a fifo so this script owns the subscriber pid. On
# SIGKILL the subscriber dies of SIGPIPE on its next write and bspwm
# drops the subscription.
mkfifo "$fifo" || exit 1
bspc subscribe "${EVENTS[@]}" > "$fifo" &
subscriber=$!

# Opening the read end unblocks the subscriber's redirect; unlinking right
# after leaves no stale fifo behind.
exec 3< "$fifo" || exit 1
rm -f "$fifo"

# quickshell started this script, so if it dies (hot reload, crash) nobody
# would start us again; exit as soon as it is gone. BSPWM_WS_OWNER overrides
# the check, which matters when started by hand under setsid.
owner=${BSPWM_WS_OWNER:-$PPID}

still_wanted() {
    kill -0 "$subscriber" 2>/dev/null || return 1
    [[ -z $owner || $owner == 0 ]] && return 0
    kill -0 "$owner" 2>/dev/null
}

publish

# Block until bspwm reports something, then snapshot unless the previous
# write is still fresh. Events keep getting drained during the wait,
# otherwise a stalled reader would block bspwm's event loop.
throttle_us=$(awk -v t="$THROTTLE" 'BEGIN { printf "%d", t * 1000000 }')
# EPOCHREALTIME (bash 5.0+) gives fork-free timestamps.
[[ -n ${EPOCHREALTIME:-} ]] || {
    echo "get_workspaces.sh needs bash 5.0+ for \$EPOCHREALTIME" >&2
    exit 1
}
last_emit=0
while still_wanted; do
    IFS= read -r -t "$IDLE" -u 3 _
    rc=$?
    if ((rc != 0)); then
        # Timeout means bspwm is quiet; a failed read means the subscriber
        # is gone and still_wanted ends the loop on the next turn.
        ((rc > 128)) || sleep 0.2
        continue
    fi

    # Leading edge publish; keep draining while waiting so bspwm never blocks.
    while :; do
        now_us=${EPOCHREALTIME/./}
        (((now_us - last_emit) >= throttle_us)) && break
        IFS= read -r -t 0.02 -u 3 _
    done

    publish
    last_emit=${EPOCHREALTIME/./}
done
