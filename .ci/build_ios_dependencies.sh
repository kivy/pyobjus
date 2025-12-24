#!/bin/bash

set -e

LIBFFI_VERSION="3.5.2"
LIBFFI_URL="https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz"
BUILD_DIR="ios-deps-build"
INSTALL_DIR="$(pwd)/ios-deps-install"

# Get this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

download_libffi() {
    curl -L "$LIBFFI_URL" | tar xz
}

generate_darwin_source_and_headers() {
    cd "libffi-${LIBFFI_VERSION}"

    git apply "$SCRIPT_DIR/disable-armv7-xcodeproj.patch"

    sed -i.bak "s/build_target(ios_device_armv7_platform, platform_headers)/print('skipping armv7')/g" generate-darwin-source-and-headers.py
    python3  generate-darwin-source-and-headers.py --only-ios
    cd ..
}

build_for_platform() {
    local platform=$1
    local arch=$2
    local sdk=$3
    
    cd "libffi-${LIBFFI_VERSION}"

    xcodebuild ONLY_ACTIVE_ARCH=NO ARCHS="$arch" -sdk "$sdk" -project libffi.xcodeproj -target libffi-iOS -configuration Release

    # Copy result to install directory
    local dest_dir="$INSTALL_DIR/$platform/$arch"
    mkdir -p "$dest_dir/lib"
    cp "build/Release-$sdk/libffi.a" "$dest_dir/lib/"
    mkdir -p "$dest_dir/include"
    cp -r "include" "$dest_dir/include/ffi"
    cd ..
}


# Delete previous build and install directories
rm -rf "$BUILD_DIR" "$INSTALL_DIR"

mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

download_libffi

generate_darwin_source_and_headers

# Build for iphoneos (arm64)
build_for_platform "iphoneos" "arm64" "iphoneos"

# Build for iphonesimulator (x86_64)
build_for_platform "iphonesimulator" "x86_64" "iphonesimulator"
build_for_platform "iphonesimulator" "arm64" "iphonesimulator"

echo "libffi built successfully for iphoneos and iphonesimulator"