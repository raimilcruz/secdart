import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/plugin/outline_mixin.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';


class SecDartPlugin extends ServerPlugin {
  SecDartPlugin(ResourceProvider provider) : super(provider);

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) {
    //Taken from angular_plugin
    final root = new ContextRoot(contextRoot.root, contextRoot.exclude)
      ..optionsFilePath = contextRoot.optionsFile;
    if (!isEnabled(root.optionsFilePath)) {
      return null;
    }

    final logger = new PerformanceLog(new StringBuffer());
    final builder = new ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = logger
      ..fileContentOverlay = fileContentOverlay;
    final dartDriver = builder.buildDriver(root);

    final sourceFactory = dartDriver.sourceFactory;

    final driver = new SecDriver(
        new ChannelNotificationManager(channel),
        dartDriver,
        analysisDriverScheduler,
        sourceFactory,
        fileContentOverlay);
    return driver;
  }

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => "SecDart Plugin";

  @override
  String get version => "0.0.1";

  @override
  bool isCompatibleWith(Version serverVersion) => true;
}
class ChannelNotificationManager implements NotificationManager {
  final PluginCommunicationChannel channel;

  ChannelNotificationManager(this.channel);

  @override
  void recordAnalysisErrors(
      String path, LineInfo lineInfo, List<AnalysisError> analysisErrors) {
    final converter = new AnalyzerConverter();
    final errors = converter.convertAnalysisErrors(
      analysisErrors,
      lineInfo: lineInfo,
    );
    channel.sendNotification(
        new plugin.AnalysisErrorsParams(path, errors).toNotification());
  }
}