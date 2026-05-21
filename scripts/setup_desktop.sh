#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Install lightweight desktop and VNC server
apt-get update
apt-get install -y xfce4 xfce4-terminal tigervnc-standalone-server dbus-x11

# Configure VNC password
mkdir -p /root/.vnc
echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# VNC startup script
cat > /root/.vnc/xstartup << 'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
XSTARTUP
chmod +x /root/.vnc/xstartup

# Start VNC server on display :1 (port 5901)
vncserver :1 -geometry 1280x800 -depth 24 -localhost no
