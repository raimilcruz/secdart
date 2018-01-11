import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:plugin/src/plugin_impl.dart';

import 'package:secdart_analyzer/src/experimental/task.dart';

/**
 * This file contains function to initialize AnalysisContext that are used by the Security Analyzer
 **/

AnalysisContext createAnalysisContext([bool addTasks = false]) {
  DartSdk sdk = getDarkSdk();

  if (addTasks) {
    _addSecDartTask();
  }

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();

  //contribute to DART_ERRORS by hacking the extension point of the EnginePlugin
  if (addTasks) {
    _contributeToDartErrors();
  }

  context.sourceFactory = new SourceFactory([
    new DartUriResolver(sdk),
    new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)
  ]);

  context.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;
  return context;
}

void _addSecDartTask() {
  var taskMap = AnalysisEngine.instance.taskManager.taskMap;
  //generate errors
  taskMap.putIfAbsent(
      SECDART_ERRORS, () => [GradualSecurityVerifyUnitTask.DESCRIPTOR]);
  //the flag to indicate that the SecurityTask can run
  taskMap.putIfAbsent(READY_SECURITY_ANALYSIS,
      () => [GradualSecurityVerifyUnitTask.DESCRIPTOR]);
  //the top level task to invoke
  taskMap.putIfAbsent(SEC_ELEMENT, () => [SecurityTask.DESCRIPTOR]);

  //register ResolveSecurityAnnotationTask
  taskMap.putIfAbsent(
      SEC_RESOLVED_UNIT1, () => [ResolveSecurityAnnotationTask.DESCRIPTOR]);
  taskMap.putIfAbsent(
      SEC_PARSER_ERRORS, () => [ResolveSecurityAnnotationTask.DESCRIPTOR]);

  taskMap.putIfAbsent(SEC_LIBRARY_ELEMENT_1,
      () => [ResolvedSecurityUnit1InLibraryTask.DESCRIPTOR]);
  taskMap.putIfAbsent(READY_SEC_LIBRARY_ELEMENT1,
      () => [ReadySecurityInformationForLibraryTask.DESCRIPTOR]);
}

void _contributeToDartErrors() {
  //a hack here to contribute with my extension
  ExtensionPointImpl extensionPoint = AnalysisEngine.instance.enginePlugin
      .dartErrorsForUnitExtensionPoint as ExtensionPointImpl;
  extensionPoint.add(SECDART_ERRORS);
  extensionPoint.add(SEC_PARSER_ERRORS);
}

DartSdk getDarkSdk() {
  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var dartSdkDirectory = getSdkPath();
  DartSdk sdk = new FolderBasedDartSdk(
      resourceProvider, resourceProvider.getFolder(dartSdkDirectory));
  return sdk;
}
