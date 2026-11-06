#!/bin/bash
# Build, sign and (optionally) upload the iOS app — no Apple ID in Xcode needed.
#
#   app/tool/ios_release.sh            # build + sign -> build/ios/ipa/osg_app.ipa
#   app/tool/ios_release.sh --upload   # ... and upload to App Store Connect (TestFlight)
#
# Signing uses an App Store Connect API key (Admin) in
# ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8 and Xcode's
# cloud-managed distribution certificate. Set these environment variables:
#   ASC_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID Why the detour:
#   - `xcodebuild archive` with automatic signing wants a *development* profile,
#     and that needs an Apple ID signed in to Xcode (the API key is refused:
#     "Authentication failed").
#   - So: archive unsigned, then sign app + widget locally ("-") with their
#     .entitlements so the App Group (group.uz.kudratov.osg) request is in the
#     binary, then `-exportArchive` re-signs for the App Store via the API key.
#     Without the local step the export drops the App Group and the widget can't
#     read the words.
# Raise the build number in pubspec.yaml (version: X.Y.Z+N) before every upload.
set -euo pipefail

TEAM=${ASC_TEAM_ID:?set ASC_TEAM_ID (Apple Developer team ID)}
KEY_ID=${ASC_KEY_ID:?set ASC_KEY_ID (App Store Connect API key ID)}
ISSUER=${ASC_ISSUER_ID:?set ASC_ISSUER_ID (App Store Connect issuer ID)}
KEY="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
API_BASE_URL=https://osg.kudratov.uz

cd "$(dirname "$0")/.."
[ -f "$KEY" ] || { echo "missing $KEY"; exit 1; }

ARCHIVE=build/ios/archive/Runner.xcarchive
OUT=build/ios/ipa
OPTS=$(mktemp -t ExportOptions).plist
cat > "$OPTS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$TEAM</string>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
EOF
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY" -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER")

echo "== 1/4 Flutter (clean cache, release config)"
rm -rf .dart_tool/flutter_build "$ARCHIVE" "$OUT"
flutter build ios --release --config-only --dart-define=API_BASE_URL=$API_BASE_URL

echo "== 2/4 archive (unsigned)"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" archive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM=$TEAM -quiet

echo "== 3/4 embed entitlements (App Group) + export signed IPA"
APP="$ARCHIVE/Products/Applications/Runner.app"
codesign --force --sign - --entitlements ios/OsgWidgetExtension/OsgWidgetExtension.entitlements "$APP/PlugIns/OsgWidgetExtension.appex"
codesign --force --sign - --entitlements ios/Runner/Runner.entitlements "$APP"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$OUT" -exportOptionsPlist "$OPTS" "${AUTH[@]}" -quiet

IPA=$(ls "$OUT"/*.ipa)
T=$(mktemp -d); unzip -q "$IPA" -d "$T"
for x in "$T/Payload/Runner.app" "$T/Payload/Runner.app/PlugIns/OsgWidgetExtension.appex"; do
  codesign -d --entitlements - --xml "$x" 2>/dev/null | plutil -p - | grep -q "group.uz.kudratov.osg" \
    || { echo "App Group missing in $(basename "$x") - not uploading"; exit 1; }
done
# (no `grep -m1`/`head` here: with pipefail, the early exit SIGPIPEs codesign
# and the whole script stops with 141 before the upload)
codesign -dvv "$T/Payload/Runner.app" 2>&1 | grep "Authority=Apple Distribution" \
  || { echo "not signed with Apple Distribution - not uploading"; exit 1; }
echo "built $IPA"

if [ "${1:-}" = "--upload" ]; then
  echo "== 4/4 upload to App Store Connect"
  xcrun altool --upload-app -f "$IPA" -t ios --apiKey "$KEY_ID" --apiIssuer "$ISSUER"
fi
