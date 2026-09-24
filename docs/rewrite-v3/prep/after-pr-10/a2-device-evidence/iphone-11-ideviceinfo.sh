#!/bin/bash
# Captures iphone-11-ideviceinfo.txt: selected ideviceinfo keys, each command beside its output.
# No UDID, ECID or serial key is queried; the -u argument is shown as [redacted].
set -u
UDID=$(idevice_id -l | head -1)
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  echo "\$ ideviceinfo --version"; ideviceinfo --version; echo "exit=$?"
  for k in ProductType ModelNumber RegionInfo HardwareModel CPUArchitecture ProductVersion BuildVersion; do
    echo "\$ ideviceinfo -u [redacted] -k $k"; ideviceinfo -u "$UDID" -k "$k"; echo "exit=$?"
  done
} > iphone-11-ideviceinfo.txt
