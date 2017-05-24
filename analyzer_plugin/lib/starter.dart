import 'dart:async';

import 'package:analyzer/error/error.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analysis_server/protocol/protocol.dart' show Request;
import 'package:analysis_server/protocol/protocol_generated.dart'
    show CompletionGetSuggestionsParams, CompletionGetSuggestionsResult;
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:secdart_analyzer_plugin/src/secdriver.dart';

class Starter {
  final secDrivers = <String, SecDriver>{};
  AnalysisServer server;

  void start(AnalysisServer server) {
    this.server = server;
    ContextBuilder.onCreateAnalysisDriver = onCreateAnalysisDriver;
    server.onResultErrorSupplementor = sumErrors;
    server.onNoAnalysisResult = readHowToImplementonNoAnalysisResult;
    server.onNoAnalysisCompletion = readHowToImplementonNoAnalysisCompletion;
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

   final SecDriver driver = new SecDriver(server, analysisDriver,
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
      final angularErrors = await driver.requestDartErrors(path);
      errors.addAll(angularErrors);
    }
    return null;
  }

  Future readHowToImplementonNoAnalysisResult(String path, Function sendFn) async {
    for (final driverPath in secDrivers.keys) {
      if (server.contextManager.getContextFolderFor(path).path == driverPath) {
        final driver = secDrivers[driverPath];
        // only the owning driver "adds" the path
        final angularErrors = await driver.requestDartErrors(path);
        sendFn(
            driver.dartDriver.analysisOptions,
            new LineInfo.fromContent(driver.getFileContent(path)),
            angularErrors);
        return;
      }
    }

    sendFn(null, null, null);
  }

  // Handles .html completion. Directly sends the suggestions to the
  // [completionHandler].
  Future readHowToImplementonNoAnalysisCompletion(
    Request request,
    CompletionDomainHandler completionHandler,
    CompletionGetSuggestionsParams params,
    CompletionPerformance performance,
    String completionId,
  ) async {
   /* var filePath = (request.toJson()['params'] as Map)['file'];
    var source =
        new FileSource(server.resourceProvider.getFile(filePath), filePath);

    if (server.contextManager.isInAnalysisRoot(filePath)) {
      for (final driverPath in angularDrivers.keys) {
        if (server.contextManager.getContextFolderFor(filePath).path ==
            driverPath) {
          final driver = angularDrivers[driverPath];

          var completionContributor = new AngularCompletionContributor(driver);
          CompletionRequestImpl completionRequest = new CompletionRequestImpl(
              null, // AnalysisResult - unneeded for AngularCompletion
              null, // AnalysisContext - unnedded for AngularCompletion
              server.resourceProvider,
              source,
              params.offset,
              performance,
              server.ideOptions);
          completionHandler.setNewRequest(completionRequest);
          server.sendResponse(new CompletionGetSuggestionsResult(completionId)
              .toResponse(request.id));
          var suggestions =
              await completionContributor.computeSuggestions(completionRequest);
          completionHandler.sendCompletionNotification(
              completionId,
              completionRequest.replacementOffset,
              completionRequest.replacementLength,
              suggestions);
          completionHandler.ifMatchesRequestClear(completionRequest);
        }
      }
    }*/
  }
}
