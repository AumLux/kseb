#!/usr/bin/env bash
# Assembles the public site from already-built artifacts:
#   tools/ci/assemble-site.sh <env> <web-dir> <apk> <out-dir>
# Layout: /index.html (landing), /web/ (Flutter web app), /downloads/*.apk,
# /version.json, /CNAME. Needs: qrencode, aapt (optional, for the version).
set -euo pipefail

ENV_NAME="$1"; WEB="$2"; APK="$3"; OUT="$4"
DOMAIN="${SITE_DOMAIN:-aumlux.simplewebsite.in}"
REPO="${GITHUB_REPOSITORY:-AumLux/kseb}"
COMMIT="${GITHUB_SHA:-local}"
BRANCH="${GITHUB_REF_NAME:-local}"
BUILD="${BUILD_NUMBER:-0}"
VERSION="$(grep -m1 '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//; s/+.*//')"
MIRROR_TAG="${MIRROR_TAG:-preview}"

test -s "$WEB/index.html"
test -s "$APK"

rm -rf "$OUT"
mkdir -p "$OUT/web" "$OUT/downloads"
cp -R "$WEB/." "$OUT/web/"
APK_NAME="aumlux-${VERSION}-${BUILD}.apk"
cp "$APK" "$OUT/downloads/$APK_NAME"
cp "$APK" "$OUT/downloads/aumlux.apk"   # stable link for older shares
SHA256="$(sha256sum "$APK" | cut -d' ' -f1)"
echo "$SHA256  $APK_NAME" > "$OUT/downloads/$APK_NAME.sha256"
SIZE_MB="$(awk -v b="$(stat -c%s "$APK")" 'BEGIN { printf "%.1f MB", b / 1048576 }')"

APK_URL="downloads/$APK_NAME"
APK_MIRROR="https://github.com/$REPO/releases/download/$MIRROR_TAG/aumlux.apk"
QR_SVG="$(qrencode -t SVG -m 1 -o - "https://$DOMAIN/$APK_URL" | sed '1,/<svg/{/<svg/!d}' | tr -d '\n')"
case "$ENV_NAME" in
  production) ENV_LABEL="Production" ;;
  *) ENV_LABEL="Preview" ;;
esac
DATE="$(date -u +"%Y-%m-%d %H:%M UTC")"
DATE_HUMAN="$(TZ=Asia/Kolkata date +"%d %b %Y")"

export VERSION BUILD ENV_LABEL APK_URL APK_MIRROR SHA256 DATE DATE_HUMAN COMMIT BRANCH REPO QR_SVG
export APK_SIZE="$SIZE_MB" SHA_SHORT="${SHA256:0:12}" COMMIT_SHORT="${COMMIT:0:7}"
python3 - "$OUT/index.html" <<'PY'
import os, sys
html = open('tools/ci/landing.html', encoding='utf-8').read()
keys = ['VERSION', 'BUILD', 'ENV_LABEL', 'APK_URL', 'APK_MIRROR', 'APK_SIZE', 'SHA256', 'SHA_SHORT',
        'DATE', 'DATE_HUMAN', 'COMMIT', 'COMMIT_SHORT', 'BRANCH', 'REPO', 'QR_SVG']
for k in keys:
    html = html.replace('{{' + k + '}}', os.environ[k])
assert '{{' not in html, 'unfilled placeholder'
open(sys.argv[1], 'w', encoding='utf-8').write(html)
PY

cp "$OUT/index.html" "$OUT/download-apk.html"
cp "$OUT/index.html" "$OUT/404.html"
echo "$DOMAIN" > "$OUT/CNAME"
touch "$OUT/.nojekyll"
cat > "$OUT/version.json" <<EOF
{"version":"$VERSION","build":$BUILD,"environment":"$ENV_NAME","apk":"/$APK_URL","sha256":"$SHA256","commit":"$COMMIT","published":"$DATE"}
EOF
cat > "$OUT/release-metadata.txt" <<EOF
environment=$ENV_NAME
build_number=$BUILD
branch=$BRANCH
commit=$COMMIT
run_id=${GITHUB_RUN_ID:-local}
built_at=$DATE
EOF
echo "Site assembled in $OUT ($APK_NAME, $SIZE_MB)"
