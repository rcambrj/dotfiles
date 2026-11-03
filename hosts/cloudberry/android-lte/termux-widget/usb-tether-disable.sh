#!/system/bin/sh

state_dir="/data/data/com.termux/files/home/.local/state/usb-tether"
mkdir -p "$state_dir"
printf '%s\n' disabled > "$state_dir/enabled"
