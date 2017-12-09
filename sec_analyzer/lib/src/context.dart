import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;


/**
 * This file contains function to initialize AnalysisContext that are used by the Security Analyzer
 **/

/**
 * Create an analysis context
 */
AnalysisContext createAnalysisContext() {
  DartSdk sdk = getDarkSdk();

  AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();

  context.sourceFactory =
    new SourceFactory([new DartUriResolver(sdk),
    new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)]);

  context.analysisOptions = new AnalysisOptionsImpl()
    ..strongMode = true;
  return context;
}
DartSdk getDarkSdk() {
  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var dartSdkDirectory = getSdkPath();
  DartSdk sdk = new FolderBasedDartSdk(
      resourceProvider, resourceProvider.getFolder(dartSdkDirectory));
  return sdk;
}