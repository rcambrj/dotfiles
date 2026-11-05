#!/data/data/com.termux/files/usr/bin/sh

state_dir="/data/data/com.termux/files/home/.local/state/usb-tether"
mkdir -p "$state_dir"
printf '%s\n' enabled > "$state_dir/enabled"

nohup /data/data/com.termux/files/home/usb-tether-watch.sh --watch \
    >>/data/data/com.termux/files/home/.local/state/usb-tether/watch.log 2>&1 &
