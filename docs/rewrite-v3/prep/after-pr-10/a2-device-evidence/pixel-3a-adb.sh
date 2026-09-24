#!/bin/bash
# Captures pixel-3a-adb.txt: Android device identity with the command beside each output.
# One Android device attached. The adb serial is replaced with [redacted] before writing.
set -u
SERIAL=$(adb get-serialno)
redact() { sed "s/$SERIAL/[redacted]/g"; }
run() { echo "\$ $*"; "$@" 2>&1 | tr -d '\r' | redact; echo "exit=${PIPESTATUS[0]}"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  run adb version
  run adb devices -l
  for p in ro.product.model ro.product.device ro.product.manufacturer ro.hardware ro.board.platform \
    ro.product.cpu.abi ro.build.version.release ro.build.version.sdk ro.build.id ro.build.fingerprint \
    ro.build.version.security_patch ro.boot.hardware.sku; do
    run adb shell getprop "$p"
  done
  run adb shell grep MemTotal /proc/meminfo
  run adb shell uname -m
} > pixel-3a-adb.txt
