// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_api;

import 'dart:async';
import 'dart:io';
import 'package:aqueduct/aqueduct.dart';
import 'package:web_api/controller/analyzer_controller.dart';
import 'package:web_api/controller/compile_controller.dart';
import 'package:web_api/helper/log_helpers.dart';
import 'package:web_api/service/analyzer_service.dart';

class WebApi extends ApplicationChannel {
  ManagedContext context;
  IAnalyzerService secAnalyzer;
  ICompilerService secCompiler;

  @override
  Future prepare() async {
    secAnalyzer = new AnalyzerService();
    secCompiler = new CompilerService();

    Controller.includeErrorDetailsInServerErrorResponses = true;

    _registerLogHandlers();
  }

  @override
  Controller get entryPoint {
    final router = Router();

    router.route("/secdartapi").link(() => AnalyzerController(secAnalyzer));

    router
        .route("/secdartapi/analyze")
        .link(() => AnalyzerController(secAnalyzer));

    router
        .route("/secdartapi/compile")
        .link(() => CompilerController(secCompiler));

    return router;
  }

  void _registerLogHandlers() {
    //logger.level = Level.ALL;
    logger.onRecord.listen((LogRecord rec) {
      FileLogger fLog = new FileLogger("app_logs.txt");
      fLog.call(rec);
    });
    if (stdout.hasTerminal) {
      logger.onRecord.listen((LogRecord record) {
        TerminalLogger tLog = new TerminalLogger();
        tLog.call(record);
      });
    }
  }
}
