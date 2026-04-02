#!/bin/bash

# Shut down all child processes on Ctrl+C or docker stop
cleanup() {
    echo "Shutting down..."
    kill $(jobs -p) 2>/dev/null
    su - user -c "vncserver -kill :1" 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

# Ensure the shared folder is writable (Docker may create it as root)
mkdir -p /home/user/shared
chown user:user /home/user/shared

# Clean up stale lock files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# Start VNC server (no password for simplicity in a local-only setup)
su - user -c "vncserver :1 -geometry 1920x1000 -depth 24 -SecurityTypes None --I-KNOW-THIS-IS-INSECURE"

# Start fluxbox window manager
su - user -c "DISPLAY=:1 fluxbox &"

# Give the desktop a moment to initialize
sleep 2

# Sync X clipboard selections so Ctrl+C/V works with noVNC's clipboard panel
su - user -c "DISPLAY=:1 autocutsel -fork"
su - user -c "DISPLAY=:1 autocutsel -selection PRIMARY -fork"

# Start desktop icons
su - user -c "DISPLAY=:1 pcmanfm --desktop &"

# Auto-start ProM
su - user -c "cd /home/user/ProM && DISPLAY=:1 ./ProM615.sh &"

# Start noVNC in the background, then wait so bash can receive signals
websockify --web /usr/share/novnc 6080 localhost:5901 &
wait
