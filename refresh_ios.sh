#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/SmartScreenTime-iOS/SmartScreenTime"
DEVICE_NAME="Wuffen"

echo "🔍 Checking wireless connection to ${DEVICE_NAME}..."
if ! xcrun devicectl list devices 2>&1 | grep -q "${DEVICE_NAME}"; then
  echo "❌ Could not find ${DEVICE_NAME}. Make sure your iPhone is on the same Wi-Fi network and unlocked."
  exit 1
fi

echo "📱 Found ${DEVICE_NAME}! Rebuilding and refreshing provisioning profile..."
xcodebuild \
  -project "${PROJECT_DIR}/SmartScreenTime.xcodeproj" \
  -scheme "SmartScreenTime (iOS)" \
  -destination "name=${DEVICE_NAME}" \
  -allowProvisioningUpdates \
  build

APP_PATH="/Users/jakedarrow/Library/Developer/Xcode/DerivedData/SmartScreenTime-dlmnmmgjnlmykbfkfocfnvdtlrsh/Build/Products/Debug-iphoneos/SmartScreenTime.app"

if [ ! -d "${APP_PATH}" ]; then
  # Fallback to build setting search if derived data path changes
  APP_PATH=$(xcodebuild -project "${PROJECT_DIR}/SmartScreenTime.xcodeproj" -scheme "SmartScreenTime (iOS)" -destination "name=${DEVICE_NAME}" -showBuildSettings | grep -m 1 " TARGET_BUILD_DIR =" | awk '{print $3}')/SmartScreenTime.app
fi

echo "🚀 Wirelessly installing SmartScreenTime to ${DEVICE_NAME}..."
xcrun devicectl device install app --device "${DEVICE_NAME}" "${APP_PATH}"

echo "✨ Launching SmartScreenTime on ${DEVICE_NAME}..."
xcrun devicectl device process launch --device "${DEVICE_NAME}" com.jakedarrow.SmartScreenTime

echo "✅ Successfully refreshed SmartScreenTime for another 7 days!"
