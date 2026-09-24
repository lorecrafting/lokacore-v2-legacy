#!/bin/bash
# Captures m1-xcode.txt: Xcode and iOS SDK identities. xcode-select still points at the
# Command Line Tools on this host, so every Xcode command sets DEVELOPER_DIR (review F13).
set -u
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
run() { echo "\$ $*"; "$@" 2>&1; echo "exit=$?"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "DEVELOPER_DIR=$DEVELOPER_DIR"
  run env -u DEVELOPER_DIR xcode-select -p
  run xcodebuild -version
  run xcodebuild -showsdks
  run xcrun --sdk iphoneos --show-sdk-version
  run xcrun --sdk iphoneos --show-sdk-build-version
} > m1-xcode.txt
