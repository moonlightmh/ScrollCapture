#!/bin/bash

# Package ScrollCapture.app with embedded OpenCV libraries

set -e

# Find the latest build in DerivedData
DERIVED_DATA_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ScrollCapture-*" -type d -maxdepth 1 | head -1)
APP_DIR="$DERIVED_DATA_PATH/Build/Products/Release/ScrollCapture.app"
FRAMEWORKS_DIR="$APP_DIR/Contents/Frameworks"
MACOS_DIR="$APP_DIR/Contents/MacOS"

echo "=== Packaging ScrollCapture.app ==="
echo "App path: $APP_DIR"

# Create Frameworks directory
mkdir -p "$FRAMEWORKS_DIR"

# OpenCV libraries to embed
OPENCV_LIBS=(
    "libopencv_core.4.13.0.dylib"
    "libopencv_imgproc.4.13.0.dylib"
    "libopencv_imgcodecs.4.13.0.dylib"
    "libopencv_features2d.4.13.0.dylib"
    "libopencv_calib3d.4.13.0.dylib"
    "libopencv_flann.4.13.0.dylib"
)

OPENCV_DIR="/opt/homebrew/opt/opencv/lib"

# Copy OpenCV libraries
echo "Copying OpenCV libraries..."
for lib in "${OPENCV_LIBS[@]}"; do
    lib_name="${lib%.4.13.0.dylib}"
    src="$OPENCV_DIR/$lib"
    dst="$FRAMEWORKS_DIR/$lib"

    cp -L "$src" "$dst"
    chmod 644 "$dst"

    # Create version symlinks
    ln -sf "$lib" "$FRAMEWORKS_DIR/${lib_name}.413.dylib"
    ln -sf "$lib" "$FRAMEWORKS_DIR/${lib_name}.dylink"
done

# Fix library paths in the app executable
echo "Fixing library paths in executable..."
for lib in "${OPENCV_LIBS[@]}"; do
    lib_name="${lib%.4.13.0.dylib}"
    old_path="/opt/homebrew/opt/opencv/lib/${lib_name}.413.dylib"
    new_path="@executable_path/../Frameworks/${lib_name}.dylink"

    install_name_tool -change "$old_path" "$new_path" "$MACOS_DIR/ScrollCapture"
done

# Fix internal OpenCV library references
echo "Fixing internal library references..."
for lib in "${OPENCV_LIBS[@]}"; do
    lib_path="$FRAMEWORKS_DIR/$lib"

    # Change id
    lib_name="${lib%.4.13.0.dylib}"
    install_name_tool -id "@executable_path/../Frameworks/${lib_name}.dylink" "$lib_path"

    # Fix references to other OpenCV libs
    for other_lib in "${OPENCV_LIBS[@]}"; do
        other_name="${other_lib%.4.13.0.dylib}"
        old_ref="/opt/homebrew/opt/opencv/lib/${other_name}.413.dylib"
        new_ref="@executable_path/../Frameworks/${other_name}.dylink"

        if otool -L "$lib_path" | grep -q "$old_ref"; then
            install_name_tool -change "$old_ref" "$new_ref" "$lib_path"
        fi
    done
done

# Re-sign the app (ad-hoc signature)
echo "Re-signing application..."
codesign --force --deep --sign - "$APP_DIR"

echo ""
echo "=== Package Complete ==="
echo "App location: $APP_DIR"

# Verify
echo ""
echo "Verifying library paths..."
otool -L "$MACOS_DIR/ScrollCapture" | grep opencv