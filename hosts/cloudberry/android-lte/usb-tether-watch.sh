#!/data/data/com.termux/files/usr/bin/sh

set -eu

state_dir="/data/data/com.termux/files/home/.local/state/usb-tether"
state_file="${state_dir}/enabled"
log_file="${state_dir}/watch.log"
interval="10"
su_bin="/data/data/com.termux/files/usr/bin/su"

mkdir -p "$state_dir"

notify() {
    if command -v termux-toast >/dev/null 2>&1; then
        termux-toast "$1"
    else
        printf '%s\n' "$1"
    fi
}

enabled() {
    [ "$(cat "$state_file" 2>/dev/null || true)" = enabled ]
}

set_state() {
    printf '%s\n' "$1" > "$state_file"
}

enable_watcher() {
    set_state enabled
    notify "USB tether watcher enabled"
}

disable_watcher() {
    set_state disabled
    notify "USB tether watcher disabled"
}

watch() {
    if ! "$su_bin" -c 'id -u' >/dev/null 2>&1; then
        printf '%s Termux does not have root access; grant it in Magisk, then enable the watcher again\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
        exit 1
    fi

    while :; do
        if enabled && ! "$su_bin" -c 'ip -br link | toybox grep -qE "^rndis[0-9]+[[:space:]]+UP([[:space:]]|$)"'; then
            printf '%s USB tethering is off; enabling rndis\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
            "$su_bin" -c 'svc usb setFunctions rndis'
        fi
        sleep "$interval"
    done
}

case "${1:-}" in
    --watch)
        watch >> "$log_file" 2>&1
        ;;
    enable)
        enable_watcher
        ;;
    disable)
        disable_watcher
        ;;
    *)
        printf 'usage: %s {enable|disable|--watch}\n' "$0" >&2
        exit 2
        ;;
esac
