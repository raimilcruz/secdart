// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_api;

import 'package:rpc/rpc.dart';
import 'package:analyzer/analyzer.dart' show AnalysisError;
import 'dart:io';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:web_api/src/application_configuration.dart';
import 'package:path/path.dart' as path;


/**
 * A simple REST API for the security analysis. This is not intented to use
 * for other project, except for the SecDart Pad.
 */
@ApiClass(version: 'v1')
class SecDartApi {
  var config = new ApplicationConfiguration("config.yaml");
  SecDartApi();

  @ApiMethod(path: 'failing')
  VoidMessage failing() {
    throw new RpcError(HttpStatus.NOT_IMPLEMENTED, 'Not Implemented',
        'I like to fail!');
  }

  @ApiMethod(path: 'hello')
  SecDartResult hello() { return new SecDartResult()..result = 'Hello there!'; }


  @ApiMethod(path: 'analyze',method: 'POST')
  SecAnalysisResult analyze(SecAnalysisInput input) {
    SecAnalyzer secAnalyzer = new SecAnalyzer();
    var errors = secAnalyzer.analyze(input.source,input.useInterval).errors;

    SecAnalysisResult result = new SecAnalysisResult();

    var issues = errors.map(_secIssueFromAnalysisError).toList();
    result.issues = issues;

    return result;
  }

  String _getLatticeFilePath(){
    return path.join(new File('.').resolveSymbolicLinksSync(),config.secdart_lattice_package);
  }

  //helper method
  SecIssue _secIssueFromAnalysisError(AnalysisError error){
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
  void setLine(String source,SecIssue issue){
  }

}

class SecDartResult {
  String result;
  SecDartResult();
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

class SecAnalysisInput{
  @ApiProperty(required: true)
  String source;

  @ApiProperty(defaultValue: false)
  bool useInterval;
}

