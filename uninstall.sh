#!/bin/bash
# Uninstallation script for alsa-relay-bridge

set -e

echo "=== ALSA Relay Bridge Uninstallation Script ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Stop and disable service
if systemctl is-active --quiet alsa-relay-volume.service; then
    echo "Stopping alsa-relay-volume service..."
    systemctl stop alsa-relay-volume.service
    echo "✓ Service stopped"
fi

if systemctl is-enabled --quiet alsa-relay-volume.service 2>/dev/null; then
    echo "Disabling alsa-relay-volume service..."
    systemctl disable alsa-relay-volume.service
    echo "✓ Service disabled"
fi

# Remove service file
if [ -f "/etc/systemd/system/alsa-relay-volume.service" ]; then
    echo "Removing systemd service file..."
    rm /etc/systemd/system/alsa-relay-volume.service
    systemctl daemon-reload
    echo "✓ Service file removed"
fi

# Remove daemon script
if [ -f "/usr/local/bin/relay-volume-daemon.py" ]; then
    echo "Removing daemon script..."
    rm /usr/local/bin/relay-volume-daemon.py
    echo "✓ Daemon script removed"
fi

# Ask about ALSA configuration
echo ""
if [ -f "/etc/asound.conf" ]; then
    if grep -q "# ALSA Relay Bridge Configuration" "/etc/asound.conf" 2>/dev/null; then
        echo "WARNING: /etc/asound.conf contains ALSA Relay Bridge configuration."
        echo "This script will NOT automatically remove it to avoid breaking your audio setup."
        echo ""
        echo "To manually remove it, edit /etc/asound.conf and remove the section"
        echo "marked with '# ALSA Relay Bridge Configuration'"
        echo ""
        echo "Backup files (if any) with pattern /etc/asound.conf.backup-* are also preserved."
    fi
fi

echo ""
echo "=== Uninstallation Complete ==="
echo ""
echo "The service has been stopped, disabled, and removed."
echo "ALSA configuration in /etc/asound.conf was preserved (manual cleanup may be needed)."
