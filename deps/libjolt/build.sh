#!/bin/bash

# Examples:
#
# ./build.sh -p source
# ./build.sh -p macos -v 5.3.0
#

# exit on error
set -e

# exit on undefined variable
set -u

# exit on pipe error
set -o pipefail

# print commands
# set -x

# Parse flags and store them in variables
platform=""
version=""
src_override=""
while getopts ":p:v:s:" opt; do
  case ${opt} in
    p ) platform=$OPTARG ;;
    v ) version=$OPTARG ;;
    s ) src_override=$OPTARG ;;
    \? ) echo "Usage: $0 [-p platform] [-v version (optional)] [-s src_override (optional)]" ;;
  esac
done

# Detect host OS

os_name=""
case "$OSTYPE" in
  darwin*)  os_name="macos" ;;
  linux*)   os_name="linux" ;;
  msys*|cygwin*|mingw*) os_name="windows" ;;
  *)        os_name="unknown: $OSTYPE" ;;
esac

if [ "$os_name" == "unknown" ]; then
  echo "❌ Unsupported OS: $OSTYPE"
  exit 1
fi

# Validate parameters

# `platform` is required
if [ -z "$platform" ]; then
  echo "❌ Platform is not specified"
  echo "Usage: $0 -p platform [-v version] [-s src_override]"
  exit 1
fi

# `version` and `src_override` are optional
# but if -s is provided, then -v must also be provided
if [ -n "$src_override" ] && [ -z "$version" ]; then
  echo "❌ If src_override (-s) is provided, then version (-v) must also be provided"
  echo "Usage: $0 -p platform [-v version] [-s src_override]"
  exit 1
fi

# If src_override is empty, we check the version
if [ -z "$src_override" ]; then
  # If version is empty, set it to the latest version from the GitHub API
  if [ -z "$version" ]; then
    # show error message for now
    echo "❌ No version provided"
    exit 1
    # echo -n "🔍 No version provided. Getting latest version from GitHub API..."
    # version=$(curl -s https://api.github.com/repos/luau-lang/luau/releases/latest | jq -r '.tag_name')
    # echo " ✅ [$version]"
  fi
fi

DEP_NAME="jolt"

# Store path of executable parent directory ("deps/libjolt")
DEP_DIR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Store path of version directory ("deps/libjolt/5.3.0")
export DEP_VERSION_DIR_PATH="${DEP_DIR_PATH}/${version}"

# If src_override is not provided, check whether the source code is present locally and download it if needed
if [ -z "$src_override" ]; then
  # Make sure the dependency source code is present
  SOURCE_CODE_PATH="${DEP_VERSION_DIR_PATH}/src"

  # check presence of ./src directory
  if [ ! -d ${SOURCE_CODE_PATH} ]; then
    echo "🔍 ${DEP_NAME} source code looks to be missing. Downloading it..."
    ${DEP_DIR_PATH}/download.sh -q -v ${version} -o ${DEP_VERSION_DIR_PATH}
  fi

  # check presence of *.cpp files in src directory or its subdirectories
  if [ -z "$(find ${SOURCE_CODE_PATH} -name '*.cpp')" ]; then
    echo "🔍 ${DEP_NAME} source code looks to be missing. Downloading it..."
    ${DEP_DIR_PATH}/download.sh -q -v ${version} -o ${DEP_VERSION_DIR_PATH}
  fi
else
  # -s is provided
  SOURCE_CODE_PATH="${src_override}"
fi

# --- Build ---

if [ "$platform" == "android" ]; then

  # make sure env var ANDROID_NDK_HOME is set
  if [ -z "${ANDROID_NDK_HOME}" ]; then
    echo "🔍 ANDROID_NDK_HOME is not set"
    exit 1
  fi

  platform_to_build="android"
  archs_to_build=("arm" "arm64" "x86" "x86_64")

elif [ "$platform" == "ios" ]; then
  platform_to_build="ios"
  archs_to_build=("arm64")
  # TODO: might want to use apple_static_library() to create a Universal Binary library
  #       https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-apple.md#apple_static_library

elif [ "$platform" == "macos" ]; then
  platform_to_build="macos"
  archs_to_build=("universal") # TODO: remove when porting this to Golang

elif [ "$platform" == "windows" ]; then
  platform_to_build="windows"
  archs_to_build=("x86_64")

elif [ "$platform" == "linux" ]; then
  platform_to_build="linux"
  archs_to_build=("x86_64")

# Special case: keep the source code.
# This is used for wasm builds.
elif [ "$platform" == "source" ]; then
  platform_to_build="source"

else
  echo "⚠️ Unsupported platform name: $platform"
  exit 1
fi

# Define the artifact name based on the platform
artifact_name="lib${DEP_NAME}.a"
artifact_destination_name=$artifact_name
bazel_command_suffix=""

if [ "$platform" == "windows" ]; then
  artifact_name="${DEP_NAME}-default.lib"
  artifact_destination_name="lib${DEP_NAME}.lib"

elif [ "$platform" == "macos" ]; then
  artifact_name="${DEP_NAME}-macos_lipo.a"
  bazel_command_suffix="--macos_cpus=arm64,x86_64"

elif [ "$platform" == "android" ]; then
  artifact_name="lib${DEP_NAME}-default.a"

elif [ "$platform" == "ios" ]; then
  artifact_name="${DEP_NAME}-ios_lipo.a" # it can be a link to the static library artifact
  bazel_command_suffix="--ios_multi_cpus=arm64"

elif [ "$platform" == "linux" ]; then
  artifact_name="lib${DEP_NAME}-default.a"

fi

if [ "$platform" == "source" ]; then

  echo "⚡️🛠️ Building $DEP_NAME $version for [$platform_to_build] on [$os_name]"

  # src is a special case. We don't prebuild it yet, and keep the source code.
  OUTPUT_DIR="$version/prebuilt/source"
  OUTPUT_DIR_INCLUDE="$OUTPUT_DIR/include"
  export OUTPUT_DIR_SRC="$OUTPUT_DIR/src"
  mkdir -p $OUTPUT_DIR
  mkdir -p $OUTPUT_DIR_INCLUDE
  mkdir -p $OUTPUT_DIR_SRC

  # copy the source code to the output directory
  # cp -r ${DEP_VERSION_DIR_PATH}/src/* ${DEP_VERSION_DIR_PATH}/prebuilt/source/src

  find ${DEP_VERSION_DIR_PATH}/src/Jolt -type f \( -name "*.h" -o -name "*.hpp" -o -name "*.c" -o -name "*.cpp" \) -exec sh -c 'mkdir -p "${2}/$(dirname ${1#${3}/})" && cp "${1}" "${2}/$(dirname ${1#${3}/})"' _ {} ${DEP_VERSION_DIR_PATH}/prebuilt/source/src ${DEP_VERSION_DIR_PATH}/src \;

  # move the header files to the output directory
  # copy and merge all include directories from src tree to output directory
  for dir in ${OUTPUT_DIR_SRC}/*/include/; do
    if [ -d "$dir" ]; then
      cp -r "$dir"* "$OUTPUT_DIR_INCLUDE/"
    fi
  done

else

  echo "⚡️🛠️ Building $DEP_NAME $version for [$platform_to_build] (${archs_to_build[@]}) on [$os_name]"

  # Create copy of  source code for bazel to find it
  # (using copy because symlinks don't work on Windows)
  rm -rf ${DEP_DIR_PATH}/src
  cp -rf ${SOURCE_CODE_PATH} ${DEP_DIR_PATH}/src

  # Build for each architecture
  for arch in "${archs_to_build[@]}"; do

    OUTPUT_DIR="$version/prebuilt/$platform_to_build/$arch"
    OUTPUT_DIR_LIB_DEBUG="$OUTPUT_DIR/lib-Debug"
    OUTPUT_DIR_LIB_RELEASE="$OUTPUT_DIR/lib-Release"
    OUTPUT_DIR_INCLUDE="$OUTPUT_DIR/include"

    # recreate output directories
    rm -rf $OUTPUT_DIR
    mkdir -p $OUTPUT_DIR_LIB_DEBUG
    mkdir -p $OUTPUT_DIR_LIB_RELEASE
    mkdir -p $OUTPUT_DIR_INCLUDE

    # build library (DEBUG)
    bazel build //deps/lib${DEP_NAME}:${DEP_NAME} --platforms=//:${platform_to_build}_${arch} --compilation_mode=dbg $bazel_command_suffix
    cp ../../bazel-bin/deps/lib${DEP_NAME}/$artifact_name $OUTPUT_DIR_LIB_DEBUG/$artifact_destination_name

    # build library (RELEASE)
    bazel build //deps/lib${DEP_NAME}:${DEP_NAME} --platforms=//:${platform_to_build}_${arch} --compilation_mode=opt $bazel_command_suffix
    cp ../../bazel-bin/deps/lib${DEP_NAME}/$artifact_name $OUTPUT_DIR_LIB_RELEASE/$artifact_destination_name

    # find all .h files in ${DEP_DIR_PATH}/src/Jolt and its subdirectories, and copy them to $OUTPUT_DIR_INCLUDE
    find ${DEP_DIR_PATH}/src/Jolt -type f \( -name "*.h" -o -name "*.inl" \) -exec sh -c 'mkdir -p "${2}/$(dirname ${1#${3}/})" && cp "${1}" "${2}/$(dirname ${1#${3}/})"' _ {} ${OUTPUT_DIR_INCLUDE} ${DEP_DIR_PATH}/src \;

  done

  # Cleanup: remove the copy of source code
  rm -rf ${DEP_DIR_PATH}/src

fi

# --- The End ---

if [ -z "${archs_to_build:-}" ]; then
  echo "✅ Done. [$platform_to_build]"
else
  echo "✅ Done. [$platform_to_build] (${archs_to_build[@]})"
fi
