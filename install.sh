#!/bin/bash
# Simple installation script for alsa-relay-bridge
# Alternative to Debian package installation

set -e

ASOUND_CONF="/etc/asound.conf"
ASOUND_BACKUP="/etc/asound.conf.backup-$(date +%Y%m%d-%H%M%S)"
RELAY_ADDR="0x21"

echo "=== ALSA Relay Bridge Installation Script ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "relay_volume.py" ] || [ ! -f "alsa-relay-volume.service" ]; then
    echo "ERROR: Must be run from the project root directory"
    exit 1
fi

# Function to check if I2C is enabled
check_i2c() {
    if [ ! -e /dev/i2c-1 ]; then
        echo "WARNING: I2C interface /dev/i2c-1 not found!"
        echo "Please enable I2C using 'sudo raspi-config' -> Interface Options -> I2C"
        return 1
    fi
    echo "✓ I2C interface detected"
    return 0
}

# Function to detect Allo RelayAttenuator hardware
check_relay_hardware() {
    if command -v i2cdetect >/dev/null 2>&1; then
        echo "Checking for Allo RelayAttenuator at address ${RELAY_ADDR}..."
        if i2cdetect -y 1 | grep -q "21"; then
            echo "✓ Allo RelayAttenuator detected at address ${RELAY_ADDR}"
            return 0
        else
            echo "WARNING: Allo RelayAttenuator not detected at address ${RELAY_ADDR}"
            echo "Please verify hardware connection and I2C configuration"
            return 1
        fi
    else
        echo "WARNING: i2cdetect not available, skipping hardware detection"
        return 1
    fi
}

# Function to check for BossDAC
check_bossdac() {
    if command -v aplay >/dev/null 2>&1; then
        if aplay -l | grep -q "BossDAC"; then
            echo "✓ Allo BossDAC detected"
            return 0
        else
            echo "WARNING: Allo BossDAC not detected in ALSA devices"
            echo "Please verify BossDAC is properly configured"
            return 1
        fi
    else
        echo "WARNING: aplay not available, skipping BossDAC detection"
        return 1
    fi
}

# Check dependencies
echo "Checking dependencies..."
MISSING_DEPS=()

if ! command -v python3 >/dev/null 2>&1; then
    MISSING_DEPS+=("python3")
fi

if ! python3 -c "import smbus" 2>/dev/null; then
    MISSING_DEPS+=("python3-smbus")
fi

if ! python3 -c "import alsaaudio" 2>/dev/null; then
    MISSING_DEPS+=("python3-alsaaudio")
fi

if ! command -v i2cdetect >/dev/null 2>&1; then
    MISSING_DEPS+=("i2c-tools")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "ERROR: Missing required dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install them with:"
    echo "  sudo apt install ${MISSING_DEPS[*]}"
    exit 1
fi

echo "✓ All dependencies present"
echo ""

# Hardware detection
echo "Hardware Detection:"
check_i2c
check_relay_hardware
check_bossdac
echo ""

# Install daemon script
echo "Installing daemon script..."
cp relay_volume.py /usr/local/bin/relay-volume-daemon.py
chmod +x /usr/local/bin/relay-volume-daemon.py
echo "✓ Daemon installed to /usr/local/bin/relay-volume-daemon.py"

# Install systemd service
echo "Installing systemd service..."
cp alsa-relay-volume.service /etc/systemd/system/
echo "✓ Service installed to /etc/systemd/system/alsa-relay-volume.service"

# Configure ALSA
echo ""
echo "Configuring ALSA..."
needs_config=true

if [ -f "$ASOUND_CONF" ]; then
    if grep -q "# ALSA Relay Bridge Configuration" "$ASOUND_CONF" 2>/dev/null; then
        echo "✓ ALSA configuration already present in $ASOUND_CONF"
        needs_config=false
    elif grep -q "pcm.boss" "$ASOUND_CONF" 2>/dev/null; then
        echo "✓ Similar ALSA configuration detected, skipping"
        needs_config=false
    else
        # Backup existing configuration
        echo "Backing up existing $ASOUND_CONF to $ASOUND_BACKUP"
        cp "$ASOUND_CONF" "$ASOUND_BACKUP"
    fi
fi

if [ "$needs_config" = true ]; then
    echo "Appending ALSA configuration to $ASOUND_CONF..."
    {
        echo ""
        echo "# ALSA Relay Bridge Configuration"
        echo "# Added by alsa-relay-bridge install script on $(date)"
        cat asound.conf
    } >> "$ASOUND_CONF"
    echo "✓ ALSA configuration added"
fi

# Enable and start service
echo ""
echo "Configuring systemd service..."
systemctl daemon-reload

if systemctl enable alsa-relay-volume.service; then
    echo "✓ Service enabled"
else
    echo "ERROR: Failed to enable service"
    exit 1
fi

if systemctl start alsa-relay-volume.service; then
    echo "✓ Service started"
else
    echo "WARNING: Service failed to start"
    echo "Check logs with: journalctl -u alsa-relay-volume.service -n 50"
fi

# Show service status
echo ""
echo "Service Status:"
systemctl status alsa-relay-volume.service --no-pager || true

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To check service status: systemctl status alsa-relay-volume.service"
echo "To view logs: journalctl -u alsa-relay-volume.service -f"
echo "To stop service: sudo systemctl stop alsa-relay-volume.service"
echo "To disable service: sudo systemctl disable alsa-relay-volume.service"
echo ""
if [ -f "$ASOUND_BACKUP" ]; then
    echo "Original ALSA config backed up to: $ASOUND_BACKUP"
fi
echo ""
echo "To uninstall, run: sudo ./uninstall.sh"
