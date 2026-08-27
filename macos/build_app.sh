#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

# 계약이 바뀌었는데 생성물이 낡았으면 여기서 막는다.
python3 ../contract/generate.py --check || exit 1
APP="딸깍 감도 조절기.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -parse-as-library -O -framework SwiftUI -framework AppKit ../contract/generated/Contract.swift SensitivityTuner.swift -o "$APP/Contents/MacOS/딸깍 감도 조절기"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>딸깍 감도 조절기</string>
  <key>CFBundleExecutable</key><string>딸깍 감도 조절기</string>
  <key>CFBundleIdentifier</key><string>kr.dongguk.ttalkkak.sensitivity-tuner</string>
  <key>CFBundleName</key><string>딸깍 감도 조절기</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
</dict></plist>
PLIST
echo "완료: $APP"
