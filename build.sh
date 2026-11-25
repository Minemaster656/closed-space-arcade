#!/bin/bash

GODOT="/usr/bin/godot"
CONFIG="export_presets.cfg"
PROJECT_NAME="closed-space-arcade"

CURRENT_VERSION=$(grep -oP "^export_path=.*$" "$CONFIG" | grep -oP "v\d+(\.\d+)+" | tail -1)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/GodotBuilds"

if [ -z "$CURRENT_VERSION" ]; then
    echo "Version not found in $CONFIG"
    echo "Defaulting to v0.1"
    NEW_VERSION="v0.1"
else
    NEW_VERSION=$(echo "$CURRENT_VERSION" | awk -F'.' '{print $1"."$2+1}')
    echo "Current version: $CURRENT_VERSION"
    echo "New version: $NEW_VERSION"
    sed -i "s|$CURRENT_VERSION|$NEW_VERSION|g" "$CONFIG"
fi

FULL_BASE_DIR="$BUILDS_DIR/$PROJECT_NAME/$NEW_VERSION"
mkdir -p "$FULL_BASE_DIR"/{windows,linux,android,web}

echo "Building $NEW_VERSION..."
echo "Output: $FULL_BASE_DIR"

export_platform() {
    local preset="$1"
    local output="$2"
    echo "Exporting $preset..."
    if $GODOT --headless --export-release "$preset" "$output" 2>&1 | tee /tmp/godot_export.log; then
        if grep -q "ERROR: Project export for preset \"$preset\" failed" /tmp/godot_export.log; then
            echo "WARNING: $preset export failed, skipping..."
            return 1
        fi
        echo "$preset: OK"
        return 0
    else
        echo "WARNING: $preset export failed, skipping..."
        return 1
    fi
}

export_platform "Windows Desktop" "$FULL_BASE_DIR/windows/closedspace.exe"
export_platform "Linux" "$FULL_BASE_DIR/linux/closedspace.x86_64"
export_platform "Android" "$FULL_BASE_DIR/android/closedspace.apk"
export_platform "Web" "$FULL_BASE_DIR/web/index.html"

if [ -f "$FULL_BASE_DIR/web/index.html" ]; then
    echo "Archiving web build..."
    cd "$FULL_BASE_DIR/web" && zip -r "../web_$NEW_VERSION.zip" .
fi

echo "Build complete: $NEW_VERSION"
echo "Location: $FULL_BASE_DIR"