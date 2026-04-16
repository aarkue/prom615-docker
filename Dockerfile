FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Use fast German mirror
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://ftp.fau.de/ubuntu|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com/ubuntu|http://ftp.fau.de/ubuntu|g' /etc/apt/sources.list

# Install BellSoft Liberica JDK 8 Full (includes JavaFX 8 - OpenJDK 8 lacks it)
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    curl -fsSL -o /tmp/liberica.deb "https://download.bell-sw.com/java/8u432+7/bellsoft-jre8u432+7-linux-amd64-full.deb" && \
    apt-get install -y --no-install-recommends /tmp/liberica.deb && \
    rm /tmp/liberica.deb && \
    rm -rf /var/lib/apt/lists/*

# Install VNC, noVNC, window manager, terminal, and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Virtual framebuffer + VNC (Xvfb provides GLX/software OpenGL, x11vnc exposes it)
    xvfb \
    x11vnc \
    novnc \
    websockify \
    fluxbox \
    pcmanfm \
    xterm \
    autocutsel \
    xclip \
    # X11 and OpenGL libs for ProM
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    fontconfig \
    libgl1-mesa-dri \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME to Liberica 8 Full (find the installed path)
RUN ln -s /usr/lib/jvm/bellsoft-java8* /usr/lib/jvm/java-8 || \
    ln -s $(dirname $(dirname $(readlink -f $(which java)))) /usr/lib/jvm/java-8
ENV JAVA_HOME=/usr/lib/jvm/java-8
ENV DISPLAY=:1
ENV LIBGL_ALWAYS_SOFTWARE=1

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
RUN mkdir -p /home/user/.fluxbox && \
    printf 'session.screen0.toolbar.visible: false\n' > /home/user/.fluxbox/init && \
    ln -s /bin/true /usr/local/bin/fbsetbg && \
    printf '%s\n' \
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
