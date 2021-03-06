#!/bin/bash

# Fast fail the script on failures.
set -e

#sec_analyzer project
cd 'sec_analyzer'

#  get dependencies
pub get

# Analyze the test first
dartanalyzer lib test

#Run tests. We run test in two groups because Travis kill the process
#when it consumes too much memory 
# first batch
dart --checked test/test_all_but_sec_checker.dart

# second batch
dart --checked test/test_all_sec_checker.dart

cd ..

#secdart project
cd 'secdart'

pub get

dartanalyzer lib

cd ..

#secdart_analyzer_plugin
cd 'secdart_analyzer_plugin'
pub get

dartanalyzer lib

cd ..

# web_api project
cd 'web_api'

pub get

dartanalyzer lib test

cd ..

# security_transformer project
cd 'security_transformer'

pub get

dartanalyzer lib test

dart --checked test/test_all.dart
