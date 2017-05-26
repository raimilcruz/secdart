// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_api;

import 'package:rpc/rpc.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError;
import 'dart:io';
import 'package:secdart_analyzer_plugin/sec-analyzer.dart';


/**
 * A simple REST API for the security analysis. This is not intented to use
 * for other project, except for the SecDart Pad.
 */
@ApiClass(version: 'v1')
class DartFlowApi {

  DartFlowApi();

  @ApiMethod(path: 'noop')
  VoidMessage noop() { return null; }

  @ApiMethod(path: 'failing')
  VoidMessage failing() {
    throw new RpcError(HttpStatus.NOT_IMPLEMENTED, 'Not Implemented',
        'I like to fail!');
  }

  @ApiMethod(path: 'hello')
  DartFlowResult hello() { return new DartFlowResult()..result = 'Hello there!'; }
  @ApiMethod(path: 'analyze',method: 'POST')
  SecAnalysisResult analyze(SecAnalysisInput input) {
    SecAnalyzer secAnalyzer = new SecAnalyzer(false);
    var errors = secAnalyzer.analyze(input.source,input.useInterval);

    SecAnalysisResult result = new SecAnalysisResult();

    var issues = errors.map(secIssueFromAnalysisError).toList();
    result.issues = issues;

    return result;
  }

  //helper method
  SecIssue secIssueFromAnalysisError(AnalysisError error){
    var issue = new SecIssue();
    issue.message = error.message;
    issue.kind = "secerror";
    issue.charLength=error.length;
    issue.charStart=error.offset;
    issue.column=0;
    issue.line =0;

    //TOODO:finish. See how the analyzer do that
    return issue;
  }
  @ApiMethod(method: 'POST', path: 'test')
  DartFlowResult test(AInput x) {
    return new DartFlowResult()..result = x.toString();
  }
  void setLine(String source,SecIssue issue){
    var parts = source.split("\n");
  }

}

class DartFlowResult {
  String result;
  DartFlowResult();
}
class SecAnalysisResult{
  List<SecIssue> issues;
  SecAnalysisResult();
}
class SecIssue{
  String kind;
  String message;
  int line;
  int charStart;
  int charLength;
  int column;
}
class AInput{
  @ApiProperty(minValue: 0, maxValue: 10)
  int val;
}

class SecAnalysisInput{
  @ApiProperty(required: true)
  String source;

  @ApiProperty(defaultValue: false)
  bool useInterval;
}

