FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install JRE, VNC, noVNC, window manager, terminal, and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Java for ProM
    openjdk-11-jre \
    # VNC and desktop
    tigervnc-standalone-server \
    novnc \
    websockify \
    fluxbox \
    pcmanfm \
    xterm \
    autocutsel \
    xclip \
    # X11 libs for ProM (64-bit)
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    fontconfig \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME (the symlink resolves the architecture-specific directory name)
RUN ln -s /usr/lib/jvm/java-11-openjdk-* /usr/lib/jvm/java-11-openjdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV DISPLAY=:1

# Create a non-root user
RUN useradd -ms /bin/bash user
WORKDIR /home/user

# Copy and extract ProM
COPY prom-6.15-all-platforms.tar.gz /tmp/prom.tar.gz
RUN mkdir -p /home/user/ProM \
    && tar -xzf /tmp/prom.tar.gz -C /home/user/ProM \
    && rm /tmp/prom.tar.gz \
    && chmod +x /home/user/ProM/ProM615.sh


# Set up Fluxbox menu (right-click desktop to access)
RUN mkdir -p /home/user/.fluxbox && printf '%s\n' \
    '[begin] (Applications)' \
    '  [exec] (ProM 6.15) {bash -c "cd /home/user/ProM && ./ProM615.sh"}' \
    '  [separator]' \
    '  [exec] (Terminal) {xterm -fa Monospace -fs 12}' \
    '  [separator]' \
    '  [exit] (Exit)' \
    '[end]' > /home/user/.fluxbox/menu

# Copy desktop icons
COPY ProM.png /home/user/icons/prom.png

# Create desktop shortcut files for pcmanfm
RUN mkdir -p /home/user/Desktop && \
    printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=ProM 6.15' \
    'Exec=bash -c "cd /home/user/ProM && ./ProM615.sh"' \
    'Icon=/home/user/icons/prom.png' \
    'Terminal=false' \
    > /home/user/Desktop/prom.desktop && \
    chmod +x /home/user/Desktop/prom.desktop && \
    printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    'Name=Terminal' \
    'Exec=xterm -fa Monospace -fs 12' \
    'Icon=utilities-terminal' \
    'Terminal=false' \
    > /home/user/Desktop/terminal.desktop && \
    chmod +x /home/user/Desktop/terminal.desktop

# Configure pcmanfm desktop mode
# Create config for both screen 0 and 1 (pcmanfm resolves the screen differently depending on version)
RUN mkdir -p /home/user/.config/pcmanfm/default && printf '%s\n' \
    '[*]' \
    'wallpaper_mode=color' \
    'desktop_bg=#2f3f4f' \
    'desktop_fg=#ffffff' \
    'desktop_shadow=#000000' \
    'show_wm_menu=1' \
    'show_documents=0' \
    'show_trash=0' \
    'show_mounts=0' \
    > /home/user/.config/pcmanfm/default/desktop-items-0.conf && \
    cp /home/user/.config/pcmanfm/default/desktop-items-0.conf \
       /home/user/.config/pcmanfm/default/desktop-items-1.conf && \
    mkdir -p /home/user/.config/libfm && \
    printf '%s\n' \
    '[config]' \
    'quick_exec=1' \
    > /home/user/.config/libfm/libfm.conf

# Fix ownership
RUN chown -R user:user /home/user

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 6080

CMD ["/start.sh"]
