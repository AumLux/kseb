#!/usr/bin/env bash
# Builds one deployable site (landing page + web app + signed APK) for an
# environment. Usage: tools/ci/build-site.sh <staging|production> <out-dir>
#
# Build number = 1000 + GitHub run number, so every CI build installs over
# the previous one and `app_settings.min_app_build` can force updates.
# Production builds must be signed with the release key (android/key.properties).
set -euo pipefail

ENV_NAME="$1"
OUT="$2"
BUILD_NUMBER=$((1000 + ${GITHUB_RUN_NUMBER:-0}))
DEFINES=(--dart-define=AUMLUX_ENV="$ENV_NAME")

flutter build apk --release --target-platform android-arm64 --build-number="$BUILD_NUMBER" "${DEFINES[@]}"

APK="build/app/outputs/flutter-apk/app-release.apk"
test -s "$APK"
unzip -tq "$APK"
BUILD_TOOLS="$(find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
CERTS="$("$BUILD_TOOLS/apksigner" verify --print-certs "$APK")"
if echo "$CERTS" | grep -q "CN=Android Debug"; then
  if [ "$ENV_NAME" = "production" ]; then
    echo "::error::Production APK is debug-signed. Add the ANDROID_KEYSTORE_* secrets."
    exit 1
  fi
  echo "::warning::Staging APK is debug-signed (no release key configured)."
fi

flutter build web --release --base-href /web/ --build-number="$BUILD_NUMBER" "${DEFINES[@]}"

rm -rf "$OUT"
mkdir -p "$OUT/web" "$OUT/downloads"
cp -R build/web/. "$OUT/web/"
cp "$APK" "$OUT/downloads/aumlux.apk"
(cd "$OUT/downloads" && sha256sum aumlux.apk > aumlux.apk.sha256)
"$BUILD_TOOLS/aapt" dump badging "$APK" > "$OUT/downloads/aumlux-apk-info.txt"

cp tools/ci/landing.html "$OUT/index.html"
if [ "$ENV_NAME" != "production" ]; then
  sed -i "s|<h1>Aumlux</h1>|<h1>Aumlux <small>($ENV_NAME)</small></h1>|" "$OUT/index.html"
fi
cp "$OUT/index.html" "$OUT/download-apk.html"
echo "aumlux.simplewebsite.in" > "$OUT/CNAME"
cat > "$OUT/release-metadata.txt" <<EOF
environment=$ENV_NAME
build_number=$BUILD_NUMBER
branch=${GITHUB_REF_NAME:-local}
commit=${GITHUB_SHA:-local}
run_id=${GITHUB_RUN_ID:-local}
built_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
