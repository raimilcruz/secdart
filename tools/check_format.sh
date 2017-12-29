#!/bin/bash

# Fast fail the script on failures.
set -e

DARTFMT_OUT=$(dartfmt -n "sec_analyzer")
if [[ ! -z "$DARTFMT_OUT" ]]; then
  printf "sec_analyzer has unformatted Dart files: \n$DARTFMT_OUT\n"
  printf "Run 'dartfmt -w sec_analyzer'"
  exit 1
fi