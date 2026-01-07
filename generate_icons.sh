#!/bin/bash

SOURCE="OFFTIFY.png"
DEST="Offtify/Resources/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source image $SOURCE not found."
    exit 1
fi

# Ensure destination exists
mkdir -p "$DEST"

# Helper function to resize
resize() {
    local size=$1
    local name=$2
    sips -z $size $size "$SOURCE" --out "$DEST/$name"
}

echo "Generating icons..."

# 16x16
resize 16 "icon_16x16.png"
resize 32 "icon_16x16@2x.png"

# 32x32
resize 32 "icon_32x32.png"
resize 64 "icon_32x32@2x.png"

# 128x128
resize 128 "icon_128x128.png"
resize 256 "icon_128x128@2x.png"

# 256x256
resize 256 "icon_256x256.png"
resize 512 "icon_256x256@2x.png"

# 512x512
resize 512 "icon_512x512.png"
resize 1024 "icon_512x512@2x.png"

echo "Done."
