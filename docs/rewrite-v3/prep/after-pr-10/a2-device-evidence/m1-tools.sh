#!/bin/bash
# Records M1 toolchain identities with the command beside each output line.
set -u
cd /Users/raymondluong/dev/lokacore-a2/r1-spike/mobile || exit 1
X="mise exec elixir@1.20.4 erlang@28.4 node@24.21.0 --"
run() { echo "\$ $*"; $X "$@" 2>&1 | grep -v '^mise '; echo "exit=${PIPESTATUS[0]}"; }
date -u +%Y-%m-%dT%H:%M:%SZ
echo "host=$(sysctl -n hw.model) $(uname -m) macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
run node -v
run npm -v
run elixir --version
run erl -noshell -eval 'io:format("~s~n",[erlang:system_info(otp_release)]),{ok,V}=file:read_file(filename:join([code:root_dir(),"releases",erlang:system_info(otp_release),"OTP_VERSION"])),io:format("OTP_VERSION=~s",[V]),halt().'
run node node_modules/typescript/bin/tsc --version
run xcodebuild -version
run xcode-select -p
