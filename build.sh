#!/bin/bash

# Build script for Multi-Cloudflared Manager (mcf)
# Usage: ./build.sh

VERSION="1.1.2"
SCRIPT_NAME="mcf"
BUILD_DIR="build_artifact"
DEB_NAME="mcf_${VERSION}_all.deb"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Building $DEB_NAME...${NC}"

# Clean up
rm -rf "$BUILD_DIR"
rm -f "$DEB_NAME"

# Create structure
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/DEBIAN"

# Copy script
cp "$SCRIPT_NAME" "$BUILD_DIR/usr/local/bin/$SCRIPT_NAME"
chmod +x "$BUILD_DIR/usr/local/bin/$SCRIPT_NAME"

# Create control file
cat > "$BUILD_DIR/DEBIAN/control" <<EOF
Package: mcf
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Maintainer: caixax - dios
Description: Multi-Cloudflared Manager
 Manage multiple Cloudflare tunnels easily on Ubuntu/Debian.
EOF

# Build
dpkg-deb --build "$BUILD_DIR" "$DEB_NAME"

# Clean up build dir
rm -rf "$BUILD_DIR"

echo -e "${GREEN}Done! Package created: $DEB_NAME${NC}"
