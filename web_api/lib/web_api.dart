// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_api;

import 'dart:async';

import 'package:rpc/rpc.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError;

import 'package:secdart_analyzer/analyzer.dart';
import 'package:security_transformer/security_compiler.dart';
import 'package:web_api/src/application_configuration.dart';

/**
 * A simple REST API for the security analysis. This is not intented to use
 * for other project, except for the SecDart Pad.
 */
@ApiClass(name: 'secdartapi', version: 'v1')
class SecDartApi {
  var config = new ApplicationConfiguration("config.yaml");
  SecDartApi();

  @ApiMethod(path: 'hello')
  StringWrapper hello() {
    return new StringWrapper()..result = 'Hello. It is working!';
  }

  @ApiMethod(path: 'analyze', method: 'POST')
  SecAnalysisResult analyze(SecAnalysisInput input) {
    SecAnalyzer secAnalyzer = new SecAnalyzer();
    var errors = secAnalyzer.analyze(input.source, input.useInterval).errors;

    SecAnalysisResult result = new SecAnalysisResult();

    var issues = errors.map(_secIssueFromAnalysisError).toList();
    result.issues = issues;

    return result;
  }

  @ApiMethod(path: 'compile', method: 'POST')
  Future<SecCompileResult> compile(SecAnalysisInput input) async {
    final secCompiler = new SecurityCompiler();
    var compiled = secCompiler.compile(input.source, format: true);
    return new SecCompileResult()..compiled = compiled;
  }

  //helper method
  SecIssue _secIssueFromAnalysisError(AnalysisError error) {
    var issue = new SecIssue();
    issue.message = error.message;
    issue.kind = "secerror";
    issue.charLength = error.length;
    issue.charStart = error.offset;

    //TODO: compute line and column.
    issue.column = 0;
    issue.line = 0;
    return issue;
  }
}

class StringWrapper {
  String result;
  StringWrapper();
}

class SecAnalysisResult {
  List<SecIssue> issues;
  SecAnalysisResult();
}

class SecCompileResult {
  String compiled;
}

class SecIssue {
  String kind;
  String message;
  int line;
  int charStart;
  int charLength;
  int column;
}

class SecAnalysisInput {
  @ApiProperty(required: true)
  String source;

  @ApiProperty(defaultValue: false)
  bool useInterval;
}
