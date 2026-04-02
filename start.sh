#!/bin/bash

# Shut down all child processes on Ctrl+C or docker stop
cleanup() {
    echo "Shutting down..."
    kill $(jobs -p) 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

# Ensure the shared folder is writable (Docker may create it as root)
mkdir -p /home/user/shared
chown user:user /home/user/shared

# Clean up stale lock files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

# ProM's graphviz plugin tries to extract bundled dot binaries from the JAR to
# /tmp/.prom-graphviz/dotBinariesN/ at runtime. This extraction can fail (observed
# on Apple Silicon Macs). Pre-populate from the installed plugin package to avoid it.
GRAPHVIZ_SRC=$(ls -d /home/user/ProM/packages/graphviz-*/lib/dotBinaries 2>/dev/null | head -1)
if [ -n "$GRAPHVIZ_SRC" ]; then
    for v in "" 6 7 8 9 10; do
        dir="/tmp/.prom-graphviz/dotBinaries${v}"
        if [ ! -d "$dir" ]; then
            cp -a "$GRAPHVIZ_SRC" "$dir"
        fi
    done
    chown -R user:user /tmp/.prom-graphviz
fi

# Start Xvfb (virtual framebuffer with GLX/OpenGL software rendering support)
Xvfb :1 -screen 0 1920x1000x24 +extension GLX &
sleep 1

# Start x11vnc to expose the Xvfb display over VNC (port 5900)
x11vnc -display :1 -nopw -forever -shared -rfbport 5900 &

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
websockify --web /usr/share/novnc 6080 localhost:5900 &
wait
