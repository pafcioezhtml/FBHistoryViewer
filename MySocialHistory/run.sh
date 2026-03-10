#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building..."
xcodebuild -project FBHistoryViewer.xcodeproj \
           -scheme FBHistoryViewer \
           -configuration Debug \
           build 2>&1 | grep -E "(error:|warning:|Build succeeded|Build FAILED|Compiling)"

APP=$(xcodebuild -project FBHistoryViewer.xcodeproj \
                 -scheme FBHistoryViewer \
                 -configuration Debug \
                 -showBuildSettings 2>/dev/null \
     | grep " BUILT_PRODUCTS_DIR " | awk '{print $3}')/FBHistoryViewer.app

echo "Launching $APP"
pkill -x FBHistoryViewer 2>/dev/null || true
sleep 0.3
open "$APP"
