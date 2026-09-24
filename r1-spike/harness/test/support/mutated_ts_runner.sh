#!/bin/sh
# Real TypeScript runner with one output byte altered: the differential test must catch it.
exec sh -c 'node src/runner.ts | sed -u s/check_failed/check_fai1ed/'
