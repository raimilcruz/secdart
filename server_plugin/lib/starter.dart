import 'dart:async';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:secdart_analyzer_plugin/src/secdriver.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;

class ServerNotificationManager implements NotificationManager {
  final AnalysisServer server;
  final AnalysisDriver dartDriver;

  ServerNotificationManager(this.server, this.dartDriver);

  @override
  void recordAnalysisErrors(
      String path, LineInfo lineInfo, List<AnalysisError> analysisErrors) =>
      server.notificationManager.recordAnalysisErrors(
          'secPlugin',
          path,
          protocol.doAnalysisError_listFromEngine(
              dartDriver.analysisOptions, lineInfo, analysisErrors));
}

class Starter {
  final secDrivers = <String, SecDriver>{};
  AnalysisServer server;

  void start(AnalysisServer server) {
    this.server = server;
    ContextBuilder.onCreateAnalysisDriver = onCreateAnalysisDriver;
    server.onResultErrorSupplementor = sumErrors;
  }

  void onCreateAnalysisDriver(
      analysisDriver,
      scheduler,
      logger,
      resourceProvider,
      byteStore,
      contentOverlay,
      driverPath,
      sourceFactory,
      analysisOptions) {

   final SecDriver driver = new SecDriver(new ServerNotificationManager(server, analysisDriver), analysisDriver,
        scheduler,sourceFactory, contentOverlay);

    secDrivers[driverPath] = driver;
    server.onFileAdded.listen((String path) {
      if (server.contextManager.getContextFolderFor(path).path == driverPath) {
        // only the owning driver "adds" the path
        driver.addFile(path);
      } else {
        // but the addition of a file is a "change" to all the other drivers
        driver.fileChanged(path);
      }
    });
    server.onFileChanged.listen((String path) {
      // all drivers get change notification
      driver.fileChanged(path);
    });
  }

  Future sumErrors(String path, List<AnalysisError> errors) async {
   for (final driver in secDrivers.values) {
      final secErrors = await driver.requestDartErrors(path);
      errors.addAll(secErrors);
    }
    return null;
  }
}
