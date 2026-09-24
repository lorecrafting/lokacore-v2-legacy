#!/bin/bash
# Captures m1-air-host.txt: the A2 common host's identity with the command beside each output.
set -u
run() { echo "\$ $*"; "$@" 2>&1; echo "exit=$?"; }
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  run sysctl hw.model machdep.cpu.brand_string hw.ncpu hw.perflevel0.physicalcpu hw.perflevel1.physicalcpu hw.memsize
  run sw_vers
  run uname -m
} > m1-air-host.txt
