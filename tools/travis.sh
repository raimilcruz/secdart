#!/bin/bash

# Fast fail the script on failures.
set -e

cd 'sec_analyzer'

#  get dependencies
pub get

# Analyze the test first
dartanalyzer lib test

# Run the actual tests
dart --checked test/test_all.dart