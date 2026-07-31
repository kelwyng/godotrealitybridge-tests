#!/bin/bash
set -euo pipefail

TARGET="${1:-}"
DEVICE_ID="${2:-${VISIONOS_DEVICE_ID:-}}"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_GODOT="$PROJECT_DIR/../godotrealitybridge/godotrealitykit/out/shared_workspace/deps/debug/godot/bin/godot_macos_editor_dev.app/Contents/MacOS/Godot"
GODOT="${GODOT_REALITYKIT_EDITOR:-$DEFAULT_GODOT}"
RUN_DIR="$PROJECT_DIR/out/deploy/$TARGET"
XCODEPROJ="$RUN_DIR/godotrealitykit-demo.xcodeproj"
DERIVED_DATA="$RUN_DIR/DerivedData"
SCHEME="godotrealitykit-demo"
BUNDLE_ID="com.sample.godotrealitykit"
DEVELOPMENT_TEAM="BW399HMB92"

if [[ "$TARGET" != "simulator" && "$TARGET" != "headset" ]]; then
	echo "Usage: $0 simulator [simulator-udid]"
	echo "       $0 headset [device-id]"
	exit 2
fi

rm -rf "$RUN_DIR"
mkdir -p "$RUN_DIR"
"$GODOT" --headless --path "$PROJECT_DIR" --export-debug visionOS "$XCODEPROJ"

if [[ "$TARGET" == "simulator" ]]; then
	if [[ -z "$DEVICE_ID" ]]; then
		DEVICE_ID="$(xcrun simctl list devices booted | awk -F '[()]' '/Apple Vision Pro.*Booted/{print $2; exit}')"
	fi
	if [[ -z "$DEVICE_ID" ]]; then
		DEVICE_ID="$(xcrun simctl list devices available | awk -F '[()]' '/Apple Vision Pro/{print $2; exit}')"
		[[ -n "$DEVICE_ID" ]] || { echo "No visionOS simulator is installed."; exit 1; }
		xcrun simctl boot "$DEVICE_ID"
	fi
	open -a Simulator
	xcrun simctl bootstatus "$DEVICE_ID" -b
	SDK="xrsimulator"
	DESTINATION="platform=visionOS Simulator,id=$DEVICE_ID"
	APP_PATH="$DERIVED_DATA/Build/Products/Debug-xrsimulator/$SCHEME.app"
else
	if [[ -z "$DEVICE_ID" ]]; then
		DEVICE_ID="$(xcrun devicectl list devices | awk '/Apple Vision Pro/ && /connected/ {for (i=1; i<=NF; i++) if ($i ~ /^[0-9A-Fa-f][0-9A-Fa-f-]+$/ && length($i) > 20) {print $i; exit}}')"
	fi
	[[ -n "$DEVICE_ID" ]] || {
		echo "No connected Apple Vision Pro found. Pass its device ID as the second argument."
		xcrun devicectl list devices
		exit 1
	}
	SDK="xros"
	DESTINATION="platform=visionOS,id=$DEVICE_ID"
	APP_PATH="$DERIVED_DATA/Build/Products/Debug-xros/$SCHEME.app"
fi

BUILD_ARGS=(
	-project "$XCODEPROJ"
	-scheme "$SCHEME"
	-configuration Debug
	-sdk "$SDK"
	-destination "$DESTINATION"
	-derivedDataPath "$DERIVED_DATA"
	-allowProvisioningUpdates
	"DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM"
	CODE_SIGN_STYLE=Automatic
)
xcodebuild "${BUILD_ARGS[@]}" build

if [[ "$TARGET" == "simulator" ]]; then
	xcrun simctl install "$DEVICE_ID" "$APP_PATH"
	xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
	xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
else
	xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
	xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"
fi
