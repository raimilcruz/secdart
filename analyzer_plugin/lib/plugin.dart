import 'package:analyzer/plugin/task.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/task/model.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:secdart_analyzer/src/errors.dart';


class SecDartAnalysisPlugin implements Plugin {
  static const String UNIQUE_IDENTIFIER = 'secdart.analysis.analyzer_plugin';

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {}

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    //
    // Register contributed analysis error results.
    //
    registerExtension(DART_ERRORS_FOR_UNIT_EXTENSION_POINT_ID, SECURITY_TYPING_ERRORS);

    //
    // Register tasks.
    //
   //registerExtension(WORK_MANAGER_EXTENSION_POINT_ID, myOwnWorkManagerFactory);

  }
}