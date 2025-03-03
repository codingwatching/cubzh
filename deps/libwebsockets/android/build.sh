#!/bin/sh

set -e

START_LOCATION="$PWD"
SCRIPT_LOCATION=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Go back to start location when script exits
trap "cd $START_LOCATION" EXIT

# Go to script location
cd "$SCRIPT_LOCATION"

# Use git command to get root project directory.
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# TODO: check if docker command is available
#       and return an error if it is not

cd ${PROJECT_ROOT}

# Docker build context is expected to be <git-root>
docker build \
-t android-build-lws \
-f dockerfiles/android-build-lws.Dockerfile \
.

docker run --rm \
-v ${PROJECT_ROOT}/deps/libwebsockets/android:/export \
android-build-lws

# cd libwebsockets
# rm -rf build

# mkdir build
# cd build

# cmake .. \
# -DCMAKE_TOOLCHAIN_FILE=../contrib/iOS.cmake \
# -DLWS_OPENSSL_LIBRARIES="$PROJECT_ROOT"'/deps/libssl/ios/lib/libssl.a;'"$PROJECT_ROOT"'/deps/libssl/ios/lib/libcrypto.a' \
# -DLWS_OPENSSL_INCLUDE_DIRS="$PROJECT_ROOT"'/deps/libssl/ios/include'

# # Build using the generated Makefiles
# # ------------------------------------------------------

# make -j8

# # Copy build output into "output" directory
# # ------------------------------------------------------

# rm -rf "$PROJECT_ROOT"/deps/libwebsockets/ios/include
# rm -rf "$PROJECT_ROOT"/deps/libwebsockets/ios/lib

# cp -r ./include "$PROJECT_ROOT"/deps/libwebsockets/ios/

# mkdir "$PROJECT_ROOT"/deps/libwebsockets/ios/lib

# cp ./lib/libwebsockets.a "$PROJECT_ROOT"/deps/libwebsockets/ios/lib/libwebsockets.a