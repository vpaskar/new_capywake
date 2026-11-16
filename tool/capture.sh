#!/usr/bin/env bash
# Captures the app on the iPhone 14 Pro simulator and VERIFIES the artifact.
#
#   tool/capture.sh [screen ...]
#
# The verification is the point. `flutter test` + takeScreenshot reports
# "All tests passed!" and writes nothing, because takeScreenshot hands its
# bytes to a driver and under `flutter test` there is no driver. A capture step
# that trusted the exit code would stay green forever while docs/visual/ sat
# empty — which is how the previous project captured zero screenshots across
# 40 phases. So this script checks the files, not the status.

set -euo pipefail

DEVICE_NAME="iPhone 14 Pro"
EXPECTED_W=1179
EXPECTED_H=2556
SCREENS=("${@:-shell alarms stats}")
read -r -a SCREENS <<<"${SCREENS[*]}"

cd "$(dirname "$0")/.."

udid=$(xcrun simctl list devices available \
  | grep -F "$DEVICE_NAME (" | head -1 \
  | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')

if [[ -z "$udid" ]]; then
  echo "FAIL: no '$DEVICE_NAME' simulator available." >&2
  echo "      The mockups are 393x852pt; another device would not compare." >&2
  exit 2
fi

state=$(xcrun simctl list devices | grep -F "$udid" | grep -o '(Booted)' || true)
if [[ -z "$state" ]]; then
  echo "Booting $DEVICE_NAME ..."
  xcrun simctl boot "$udid"
  sleep 5
fi

started_at=$(date +%s)
echo "Capturing ${SCREENS[*]} on $DEVICE_NAME ($udid)"

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/capture_test.dart \
  -d "$udid"

# --- verification -----------------------------------------------------------
# Everything below exists because the command above can succeed and still have
# produced nothing.

failed=0
for screen in "${SCREENS[@]}"; do
  png="docs/visual/$screen/actual.png"

  if [[ ! -f "$png" ]]; then
    echo "FAIL: $png was not written." >&2
    failed=1
    continue
  fi

  if [[ ! -s "$png" ]]; then
    echo "FAIL: $png is empty." >&2
    failed=1
    continue
  fi

  modified_at=$(stat -f %m "$png")
  if (( modified_at < started_at )); then
    echo "FAIL: $png is stale — it predates this run." >&2
    failed=1
    continue
  fi

  read -r w h < <(
    python3 -c "
from PIL import Image
im = Image.open('$png')
print(im.size[0], im.size[1])
"
  )
  if [[ "$w" != "$EXPECTED_W" || "$h" != "$EXPECTED_H" ]]; then
    echo "FAIL: $png is ${w}x${h}, expected ${EXPECTED_W}x${EXPECTED_H}" >&2
    echo "      (393x852pt at 3x — the mockups' viewport)." >&2
    failed=1
    continue
  fi

  banner=$(
    python3 -c "
from PIL import Image
im = Image.open('$png').convert('RGB')
w, _ = im.size
# Flutter's DEBUG ribbon is a saturated red diagonal in the top-right corner.
hits = sum(
    1
    for y in range(0, 160, 4)
    for x in range(w - 160, w, 4)
    if (lambda p: p[0] > 140 and p[1] < 90 and p[2] < 90)(im.getpixel((x, y)))
)
print(hits)
"
  )
  if (( banner > 20 )); then
    echo "FAIL: $png has the DEBUG banner in its top-right corner" >&2
    echo "      ($banner red pixels). Pass showDebugBanner: false." >&2
    failed=1
    continue
  fi

  bytes=$(wc -c <"$png" | tr -d ' ')
  echo "  OK  $png  ${w}x${h}  ${bytes} bytes"
done

if (( failed )); then
  echo >&2
  echo "Capture FAILED. A green 'flutter drive' is not evidence; the PNG is." >&2
  exit 1
fi

echo "All captures verified."
