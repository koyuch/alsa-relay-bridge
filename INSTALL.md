# Installation Guide for ALSA Relay Bridge

This guide provides multiple installation methods for the ALSA Relay Bridge package.

## Quick Install from GitHub Releases

Download the latest `.deb` package from the [Releases page](https://github.com/yourusername/alsa-relay-bridge/releases):

```bash
# Download latest release (replace URL with actual release)
wget https://github.com/yourusername/alsa-relay-bridge/releases/latest/download/alsa-relay-bridge_1.0.0_all.deb

# Install
sudo apt install ./alsa-relay-bridge_1.0.0_all.deb
```

## Prerequisites

### Hardware Requirements
- Raspberry Pi (tested on Pi 3/4/5)
- Allo BossDAC
- Allo Relay Attenuator
- I2C enabled on Raspberry Pi

### Software Requirements
- Raspberry Pi OS 11 (Bullseye) or later
- Python 3.9 or later
- I2C enabled (use `sudo raspi-config` -> Interface Options -> I2C)

### Enable I2C
If I2C is not already enabled:
```bash
sudo raspi-config
# Navigate to: Interface Options -> I2C -> Enable
# Reboot after enabling
sudo reboot
```

## Installation Methods

### Method 1: Debian Package (Recommended)

This is the easiest and most automated installation method.

#### Step 1: Build the Package
```bash
# Install build dependencies
sudo apt install debhelper dpkg-dev build-essential

# Build the .deb package
chmod +x build-deb.sh
./build-deb.sh
```

#### Step 2: Install the Package
```bash
# Install the package (it will be in the parent directory)
sudo apt install ../alsa-relay-bridge_*.deb
```

The package installation will automatically:
- Install all dependencies
- Detect hardware (BossDAC and RelayAttenuator)
- Configure ALSA (backing up existing config)
- Enable and start the systemd service

#### Package Management Commands
```bash
# Check service status
systemctl status alsa-relay-volume.service

# View logs
journalctl -u alsa-relay-volume.service -f

# Stop service
sudo systemctl stop alsa-relay-volume.service

# Restart service
sudo systemctl restart alsa-relay-volume.service

# Remove package
sudo apt remove alsa-relay-bridge

# Remove package and configuration
sudo apt purge alsa-relay-bridge
```

### Method 2: Installation Script

If you prefer not to build a Debian package, use the installation script.

#### Step 1: Install Dependencies
```bash
sudo apt install python3 python3-smbus python3-alsaaudio i2c-tools
```

#### Step 2: Run Installation Script
```bash
chmod +x install.sh
sudo ./install.sh
```

The script will:
- Check for all dependencies
- Detect hardware
- Install the daemon and service files
- Configure ALSA (with backup)
- Enable and start the service

#### Uninstallation
```bash
chmod +x uninstall.sh
sudo ./uninstall.sh
```

### Method 3: Manual Installation

Follow the original manual steps from [`readme.md`](readme.md:1).

## Post-Installation

### Verify Installation

1. **Check service status:**
```bash
systemctl status alsa-relay-volume.service
```

2. **Check hardware detection:**
```bash
# Verify I2C device
i2cdetect -y 1
# Should show device at address 0x21

# Verify BossDAC
aplay -l | grep BossDAC
```

3. **Test volume control:**
```bash
# Adjust volume (0-100)
amixer -c BossDAC set Master 50%

# Check current volume
amixer -c BossDAC get Master
```

4. **View logs:**
```bash
journalctl -u alsa-relay-volume.service -f
```

### Troubleshooting

#### Service fails to start
```bash
# Check detailed logs
journalctl -u alsa-relay-volume.service -n 50 --no-pager

# Common issues:
# - I2C not enabled: sudo raspi-config -> Interface Options -> I2C
# - Hardware not connected properly
# - BossDAC not configured in ALSA
```

#### Hardware not detected
```bash
# Check I2C devices
i2cdetect -y 1

# Check ALSA cards
aplay -l

# Verify BossDAC overlay in /boot/config.txt
grep -i boss /boot/config.txt
```

#### Volume control not working
```bash
# Test relay directly
python3 -c "import smbus; bus = smbus.SMBus(1); bus.write_byte(0x21, 0x7f)"

# Check ALSA mixer
amixer -c BossDAC contents
```

## Version Management

The package uses semantic versioning (MAJOR.MINOR.PATCH):
- **1.0.0** - Initial release

To update to a new version:
```bash
# Build new version
./build-deb.sh

# Install/upgrade
sudo apt install ../alsa-relay-bridge_*.deb
```

## Configuration Files

### Installed Files
- **Daemon:** `/usr/local/bin/relay-volume-daemon.py`
- **Service:** `/lib/systemd/system/alsa-relay-volume.service`
- **ALSA Config:** `/etc/asound.conf` (modified)
- **Reference Config:** `/usr/share/alsa-relay-bridge/asound.conf`
- **Documentation:** `/usr/share/doc/alsa-relay-bridge/`

### ALSA Configuration
The installation modifies `/etc/asound.conf` to add:
- Software volume control (softvol)
- Master mixer control for BossDAC
- Hardware PCM device mapping

Original configuration is backed up to `/etc/asound.conf.backup-TIMESTAMP`

## Advanced Usage

### Custom Configuration

To modify the daemon behavior, edit [`relay_volume.py`](relay_volume.py:1):
```python
RELAY_ADDR = 0x21      # I2C address
MIN_VOL = 0x00         # Minimum volume
MAX_VOL = 0x3f         # Maximum volume (63 steps)
AUDIO_CARD = 'BossDAC' # ALSA card name
AUDIO_CONTROL = 'Master' # Mixer control name
```

After modifications:
```bash
# Rebuild package
./build-deb.sh

# Reinstall
sudo apt install ../alsa-relay-bridge_*.deb
```

### Running Without Systemd

For testing or debugging:
```bash
# Stop the service
sudo systemctl stop alsa-relay-volume.service

# Run manually
sudo /usr/local/bin/relay-volume-daemon.py
```

## Support

For issues, please check:
1. Hardware connections
2. I2C enabled and working
3. BossDAC properly configured
4. Service logs: `journalctl -u alsa-relay-volume.service`

## License

See project repository for license information.
