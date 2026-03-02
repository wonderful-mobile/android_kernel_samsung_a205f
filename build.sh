#!/usr/bin/env bash

set -e

# ---- User Config ----
PROJECT_VERSION="1.0"
DEVICE="A205F"
DEFCONFIG="exynos7885-a20_defconfig"
ARCH="arm64"
JOBS="$(nproc)"
BUILD_DIR="$(pwd)/out/build"
EXPORT_DIR="$(pwd)/out"
HOSTCFLAGS="-fcommon"
# ---------------------

DATE="$(date +"%Y-%m-%d_%H-%M-%S")"
IMAGE_SOURCE="$BUILD_DIR/arch/arm64/boot/Image"
FINAL_IMAGE="$EXPORT_DIR/kernel-${DATE}"

# ---- Environment ----
export ANDROID_MAJOR_VERSION=11
export ANDROID_PLATFORM_VERSION=11
export PLATFORM_VERSION=11

export CROSS_COMPILE=$(pwd)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export LOCALVERSION="-Wonderful-${PROJECT_VERSION}-${DEVICE}"
# ---------------------

echo ""
echo "===== Building Wonderful Kernel ====="
echo "Version: Wonderful-${PROJECT_VERSION}-${DEVICE}"
echo "Defconfig: $DEFCONFIG"
echo "Jobs: $JOBS"
echo "Build dir: $BUILD_DIR"
echo "======================================"
echo ""

# Clean
if [[ "$1" == "clean" ]]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    rm -rf "$EXPORT_DIR"
    echo "Clean complete."
    exit 0
fi

# Create build directory
mkdir -p "$BUILD_DIR"

# Generate defconfig (only if .config missing)
if [[ ! -f "$BUILD_DIR/.config" || "$1" == "defconfig" ]]; then
    echo "Generating defconfig..."
    make O="$BUILD_DIR" ARCH="$ARCH" HOSTCFLAGS="$HOSTCFLAGS" "$DEFCONFIG"

    echo "Preparing kernel..."
    make O="$BUILD_DIR" ARCH="$ARCH" prepare
fi

# Build kernel
echo "Starting build..."
echo ""

LOG_FILE="$EXPORT_DIR/build.log"
mkdir -p "$EXPORT_DIR"

# First try parallel build
if ! make -j1 \
     O="$BUILD_DIR" \
     ARCH="$ARCH" \
     HOSTCFLAGS="$HOSTCFLAGS" \
     LOCALVERSION="$LOCALVERSION" \
     2>&1 | tee "$LOG_FILE"; then

    echo ""
    echo "Parallel build failed. Retrying with -j1 for real error..."
    echo ""

    make -j1 \
         O="$BUILD_DIR" \
         ARCH="$ARCH" \
         HOSTCFLAGS="$HOSTCFLAGS" \
         LOCALVERSION="$LOCALVERSION"
fi

# Verify image
if [[ ! -f "$IMAGE_SOURCE" ]]; then
    echo "Image not found. Build failed."
    exit 1
fi

# Export image
mkdir -p "$EXPORT_DIR"
cp "$IMAGE_SOURCE" "$FINAL_IMAGE"

echo ""
echo "Build successful!"
echo "Exported to:"
echo "$FINAL_IMAGE"
echo ""
echo "Done."
