#!/bin/bash
# Build script for alsa-relay-bridge Debian package

set -e

PACKAGE_NAME="alsa-relay-bridge"
echo "=== Building ${PACKAGE_NAME} Debian Package ==="
echo ""

# Check if we're in the right directory
if [ ! -f "relay_volume.py" ] || [ ! -d "debian" ]; then
    echo "ERROR: Must be run from the project root directory"
    exit 1
fi

# Check for required build tools
echo "Checking build dependencies..."
MISSING_DEPS=()

if ! command -v dpkg-buildpackage >/dev/null 2>&1; then
    MISSING_DEPS+=("dpkg-dev")
fi

if ! command -v dh >/dev/null 2>&1; then
    MISSING_DEPS+=("debhelper")
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "ERROR: Missing required build dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install them with:"
    echo "  sudo apt install ${MISSING_DEPS[*]}"
    exit 1
fi

echo "✓ All build dependencies present"
echo ""

# Make scripts executable
echo "Setting permissions..."
chmod +x debian/postinst debian/prerm debian/postrm debian/rules
chmod +x relay_volume.py

# Clean previous builds
echo "Cleaning previous builds..."
if [ -d "debian/${PACKAGE_NAME}" ]; then
    rm -rf "debian/${PACKAGE_NAME}"
fi
rm -f ../${PACKAGE_NAME}_*.deb ../${PACKAGE_NAME}_*.changes ../${PACKAGE_NAME}_*.buildinfo ../${PACKAGE_NAME}_*.tar.* 2>/dev/null || true

# Build the package
echo ""
echo "Building package..."
# Build the package
if dpkg-buildpackage -us -uc -b; then
    echo ""
    echo "=== Build Successful ==="
    echo ""
    echo "Package files created in parent directory:"
    ls -lh ../${PACKAGE_NAME}_*.deb 2>/dev/null || true
    echo ""
    echo "To install the package:"
    echo "  sudo apt install ../${PACKAGE_NAME}_*.deb"
    echo ""
    echo "Or with dpkg:"
    echo "  sudo dpkg -i ../${PACKAGE_NAME}_*.deb"
    echo "  sudo apt-get install -f  # Install dependencies if needed"
else
    echo ""
    echo "=== Build Failed ==="
    exit 1
fi
