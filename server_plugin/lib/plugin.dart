library secdart_server_plugin;

import 'package:plugin/plugin.dart';

class SecDartServerPlugin implements Plugin {
  /**
   * The unique identifier for this plugin.
   */
  static const String UNIQUE_IDENTIFIER = 'secdart.analysis.server_plugin';

  @override
  String get uniqueIdentifier => UNIQUE_IDENTIFIER;

  @override
  void registerExtensionPoints(RegisterExtensionPoint registerExtensionPoint) {}

  @override
  void registerExtensions(RegisterExtension registerExtension) {
    //registerExtension(NAVIGATION_CONTRIBUTOR_EXTENSION_POINT_ID,
    //    new AngularNavigationContributor());
    //registerExtension(OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT_ID,
    //    new AngularOccurrencesContributor());
    //registerExtension(COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
    //    () => new AngularTemplateCompletionContributor());
    //registerExtension(COMPLETION_CONTRIBUTOR_EXTENSION_POINT_ID,
    //    () => new AngularDartCompletionContributor());
  }
}