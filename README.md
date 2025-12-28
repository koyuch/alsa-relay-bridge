# ALSA Relay Bridge

[![Build Status](https://github.com/koyuch/alsa-relay-bridge/workflows/Test%20and%20Validate/badge.svg)](https://github.com/koyuch/alsa-relay-bridge/actions)
[![Release](https://github.com/koyuch/alsa-relay-bridge/workflows/Build%20and%20Release/badge.svg)](https://github.com/koyuch/alsa-relay-bridge/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

ALSA bridge daemon for Allo RelayAttenuator volume control. Monitors ALSA mixer events and translates volume changes to relay attenuator commands via I2C.

## Features

- 🎚️ Hardware-level volume control through Allo RelayAttenuator
- 🔄 Real-time ALSA mixer event monitoring
- 🔇 Mute support
- 🚀 Automatic hardware detection
- 📦 Easy installation via Debian package or script
- 🔧 Systemd service integration
- ⚙️ Graceful configuration handling

## Hardware Requirements

- Raspberry Pi (tested on Pi 3/4/5)
- [Allo BossDAC](https://www.allo.com/sparky/boss-dac.html)
- [Allo Relay Attenuator](https://www.allo.com/sparky/relay-attenuator.html)
- I2C enabled on Raspberry Pi

## Software Requirements

- Raspberry Pi OS 11 (Bullseye) or later
- Python 3.9+ (tested up to 3.13)
- I2C enabled (`sudo raspi-config` -> Interface Options -> I2C)

## Quick Start

### Option 1: Install from GitHub Release (Recommended)

```bash
# Download latest release
wget https://github.com/koyuch/alsa-relay-bridge/releases/latest/download/alsa-relay-bridge_1.0.0_all.deb

# Install
sudo apt install ./alsa-relay-bridge_1.0.0_all.deb
```

### Option 2: Build and Install Debian Package

```bash
# Clone repository
git clone https://github.com/koyuch/alsa-relay-bridge.git
cd alsa-relay-bridge

# Build package
./build-deb.sh

# Install
sudo apt install ../alsa-relay-bridge_*.deb
```

### Option 3: Simple Installation Script

```bash
# Clone repository
git clone https://github.com/koyuch/alsa-relay-bridge.git
cd alsa-relay-bridge

# Run installation script
sudo ./install.sh
```

## What Gets Installed

The installation automatically:
- ✅ Detects hardware (I2C, RelayAttenuator, BossDAC)
- ✅ Installs daemon to `/usr/local/bin/relay-volume-daemon.py`
- ✅ Configures ALSA (backs up existing `/etc/asound.conf`)
- ✅ Installs and enables systemd service
- ✅ Starts the service

## Usage

### Check Service Status
```bash
systemctl status alsa-relay-volume.service
```

### View Logs
```bash
journalctl -u alsa-relay-volume.service -f
```

### Control Volume
```bash
# Set volume (0-100%)
amixer -c BossDAC set Master 50%

# Mute/unmute
amixer -c BossDAC set Master toggle
```

### Service Management
```bash
# Stop service
sudo systemctl stop alsa-relay-volume.service

# Restart service
sudo systemctl restart alsa-relay-volume.service

# Disable service
sudo systemctl disable alsa-relay-volume.service
```

## Uninstallation

### Debian Package
```bash
sudo apt remove alsa-relay-bridge
```

### Installation Script
```bash
sudo ./uninstall.sh
```

## Configuration

The daemon uses these default settings (in [`relay_volume.py`](relay_volume.py:1)):

```python
RELAY_ADDR = 0x21        # I2C address of RelayAttenuator
MIN_VOL = 0x00           # Minimum volume (mute)
MAX_VOL = 0x3f           # Maximum volume (63 steps)
AUDIO_CARD = 'BossDAC'   # ALSA card name
AUDIO_CONTROL = 'Master' # Mixer control name
```

To customize, edit the file and rebuild/reinstall the package.

## Documentation

- **[INSTALL.md](INSTALL.md)** - Detailed installation guide with all methods
- **[README_CICD.md](README_CICD.md)** - CI/CD pipeline documentation
- **[.github/RELEASE.md](.github/RELEASE.md)** - Release process guide

## Development

### Building Locally

```bash
# Install build dependencies
sudo apt install debhelper dpkg-dev build-essential

# Build package
./build-deb.sh
```

### Running Tests

```bash
# Install test dependencies
pip install flake8 mypy
sudo apt install shellcheck

# Run linting
flake8 relay_volume.py
mypy relay_volume.py --ignore-missing-imports
shellcheck build-deb.sh install.sh uninstall.sh
```

### CI/CD Pipeline

The project uses GitHub Actions for automated testing and releases:

- **Test Workflow**: Runs on every push/PR (Python 3.9-3.13, linting, package build)
- **Release Workflow**: Triggered by version tags (`v*.*.*`)

See [README_CICD.md](README_CICD.md) for details.

## Troubleshooting

### Service fails to start

```bash
# Check logs
journalctl -u alsa-relay-volume.service -n 50

# Common issues:
# - I2C not enabled: sudo raspi-config -> Interface Options -> I2C
# - Hardware not connected
# - BossDAC not configured
```

### Hardware not detected

```bash
# Check I2C devices
i2cdetect -y 1

# Check ALSA cards
aplay -l

# Verify BossDAC in boot config
grep -i boss /boot/config.txt
```

### Volume control not working

```bash
# Test relay directly
python3 -c "import smbus; bus = smbus.SMBus(1); bus.write_byte(0x21, 0x7f)"

# Check ALSA mixer
amixer -c BossDAC contents
```

## How It Works

1. Daemon monitors ALSA mixer events for the BossDAC Master control
2. When volume changes are detected, converts percentage (0-100) to relay steps (0-63)
3. Sends I2C commands to RelayAttenuator at address 0x21
4. Handles mute by setting volume to minimum

## Version History

See [debian/changelog](debian/changelog) for detailed version history.

**Current Version:** 1.0.0

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

[Add your license here]

## Credits

- Allo for the BossDAC and RelayAttenuator hardware
- Original manual setup instructions from the community

## Support

- **Issues**: [GitHub Issues](https://github.com/koyuch/alsa-relay-bridge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/koyuch/alsa-relay-bridge/discussions)

---

**Note:** Replace `yourusername` in URLs with your actual GitHub username before publishing.
