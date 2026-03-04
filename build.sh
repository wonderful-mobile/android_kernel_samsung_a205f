#!/usr/bin/env bash

set -e

# ---- User Config ----
PROJECT_VERSION="0.1-exp"
DEVICE="A205F"
DEFCONFIG="exynos7885-a20_defconfig"
ARCH="arm64"
JOBS="$(nproc)"
#BUILD_DIR="$(pwd)/out/build"
EXPORT_DIR="$(pwd)/out"
HOSTCFLAGS="-fcommon"
VARIENT="vanilla"
# ---------------------

DATE="$(date +"%Y-%m-%d_%H-%M-%S")"
IMAGE_SOURCE="./arch/arm64/boot/Image"
FINAL_IMAGE="$EXPORT_DIR/kernel-${DATE}"

# ---- Environment ----
export ANDROID_MAJOR_VERSION=11
export ANDROID_PLATFORM_VERSION=11
export PLATFORM_VERSION=11

export LOCALVERSION="-Wonderful-${PROJECT_VERSION}-${VARIENT}"
export KBUILD_BUILD_USER="$(whoami)"
export KBUILD_BUILD_HOST="$HOSTNAME"
export DEVICE="a20"
export DEVICE_ID="A205F"

# toolchain
export LD=aarch64-linux-gnu-ld.bfd 
export AR=aarch64-linux-gnu-ar
export RANLIB=aarch64-linux-gnu-ranlib
export NM=aarch64-linux-gnu-nm
export OBJCOPY=aarch64-linux-gnu-objcopy
export OBJDUMP=aarch64-linux-gnu-objdump
export STRIP=aarch64-linux-gnu-strip
export PATH=$(pwd)/toolchain/clang-`echo $CLANG_VERSION`/bin:$PATH
export CROSS_COMPILE=$(pwd)/toolchain/google/bin/aarch64-linux-android-
CLANG_VERSION=r416183b && echo "CLANG_VERSION=$CLANG_VERSION"
export CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3=y
# ---------------------

echo ""
echo "===== Building Wonderful Kernel ====="
echo "Version: Wonderful-${PROJECT_VERSION}-${VARIENT}"
echo "Defconfig: $DEFCONFIG"
echo "Jobs: $JOBS"
echo "Build dir: $PWD"
echo "======================================"
echo ""

# Clean
if [[ "$1" == "clean" ]]; then
    echo "Cleaning build directory..."
#    rm -rf "$BUILD_DIR"
    rm -rf "$EXPORT_DIR"
    echo "Clean complete."
    exit 0
fi

# menuconfig
if [[ "$1" == "menuconfig" ]]; then
    echo "Launching menuconfig..."
    
    # Ensure base config exists
    if [[ ! -f ".config" ]]; then
        make ARCH="$ARCH" HOSTCFLAGS="$HOSTCFLAGS" "$DEFCONFIG"
    fi

    make ARCH="$ARCH" menuconfig
    exit 0
fi

# Generate defconfig (only if .config missing)
if [[ ! -f "./.config" || "$1" == "defconfig" ]]; then
    echo "Generating defconfig..."
    make ARCH="$ARCH" HOSTCFLAGS="$HOSTCFLAGS" "$DEFCONFIG"

    echo "Preparing kernel..."
    make ARCH="$ARCH" prepare
fi

# Build kernel
echo "Starting build..."
echo ""

LOG_FILE="$EXPORT_DIR/build.log"
mkdir -p "$EXPORT_DIR"

# First try parallel build
if ! make -j"$JOBS" \
     ARCH="$ARCH" \
     HOSTCFLAGS="$HOSTCFLAGS" \
     LOCALVERSION="$LOCALVERSION" \
     2>&1 | tee "$LOG_FILE"; then

    echo ""
    echo "Parallel build failed. Retrying with -j1 for real error..."
    echo ""

    make -j1 \
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
