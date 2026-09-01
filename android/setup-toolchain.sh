#!/usr/bin/env bash
# Installs a self-contained Android SDK and Gradle under .toolchain/ so the module
# builds without a system-wide Android Studio install.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLCHAIN="$REPO_ROOT/.toolchain"
SDK="$TOOLCHAIN/android-sdk"
GRADLE_VERSION="8.11.1"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

mkdir -p "$SDK/cmdline-tools"

if [ ! -d "$SDK/cmdline-tools/latest" ]; then
  echo "Installing Android command-line tools…"
  tmp="$(mktemp -d)"
  curl -sSLo "$tmp/cmdline.zip" "$CMDLINE_TOOLS_URL"
  unzip -q "$tmp/cmdline.zip" -d "$tmp"
  mv "$tmp/cmdline-tools" "$SDK/cmdline-tools/latest"
  rm -rf "$tmp"
fi

cat > "$TOOLCHAIN/env.sh" <<'EOF'
# Self-contained Android toolchain for the EmBeLife Android port.
export ANDROID_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
EOF

# shellcheck source=/dev/null
. "$TOOLCHAIN/env.sh"

yes | sdkmanager --licenses > /dev/null 2>&1 || true
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"

if [ ! -x "$REPO_ROOT/android/gradlew" ]; then
  echo "Installing Gradle $GRADLE_VERSION to generate the wrapper…"
  tmp="$(mktemp -d)"
  curl -sSLo "$tmp/gradle.zip" "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
  unzip -q "$tmp/gradle.zip" -d "$TOOLCHAIN"
  rm -rf "$tmp"
  (cd "$REPO_ROOT/android" && "$TOOLCHAIN/gradle-${GRADLE_VERSION}/bin/gradle" wrapper --gradle-version "$GRADLE_VERSION")
fi

echo "sdk.dir=$SDK" > "$REPO_ROOT/android/local.properties"

echo
echo "Toolchain ready. Next:"
echo "  . .toolchain/env.sh && cd android && ./gradlew assembleDebug"
